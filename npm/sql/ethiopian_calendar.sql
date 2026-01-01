-- ============================================================================
-- Ethiopian Calendar Functions for PostgreSQL (Pure PL/pgSQL)
-- ============================================================================
-- 
-- This file provides Ethiopian calendar conversion functions implemented in
-- pure PL/pgSQL. No C extension or special installation required!
-- 
-- Works on ANY PostgreSQL database including:
--   - Neon, Supabase, Railway, Render
--   - AWS RDS, Azure Database, Google Cloud SQL
--   - Local PostgreSQL, Docker
-- 
-- Compatible with all ORMs: Prisma, Drizzle, TypeORM, Sequelize, Knex, etc.
-- 
-- Implementation based on algorithms from:
--   Nachum Dershowitz & Edward M. Reingold,
--   "Calendrical Calculations", Cambridge University Press.
-- 
-- The Ethiopian calendar has:
--   - 13 months: 12 months of 30 days each, plus a 13th month of 5-6 days
--   - Year starts around September 11-12 in the Gregorian calendar
--   - Leap years occur when (year % 4 == 3)
-- 
-- Author: Hulunlante Worku <hulunlante.w@gmail.com>
-- License: PostgreSQL License
-- Repository: https://github.com/HuluWZ/pg-ethiopian-calendar
-- ============================================================================

-- Ethiopian calendar epoch: August 29, 8 CE in Gregorian calendar
-- This corresponds to JDN 1724221

-- ============================================================================
-- Helper Function: Gregorian to Julian Day Number
-- ============================================================================
CREATE OR REPLACE FUNCTION _gregorian_to_jdn(
    g_year integer,
    g_month integer,
    g_day integer
)
RETURNS integer
LANGUAGE plpgsql
IMMUTABLE STRICT
AS $$
DECLARE
    a integer;
    y integer;
    m integer;
    jdn integer;
BEGIN
    -- Adjust for January/February
    a := (14 - g_month) / 12;
    y := g_year + 4800 - a;
    m := g_month + 12 * a - 3;
    
    -- Calculate Julian Day Number
    jdn := g_day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045;
    
    RETURN jdn;
END;
$$;

COMMENT ON FUNCTION _gregorian_to_jdn(integer, integer, integer) IS
'Internal helper: Converts Gregorian date components to Julian Day Number.';

-- ============================================================================
-- Helper Function: Julian Day Number to Gregorian
-- ============================================================================
CREATE OR REPLACE FUNCTION _jdn_to_gregorian(jdn integer)
RETURNS TABLE(g_year integer, g_month integer, g_day integer)
LANGUAGE plpgsql
IMMUTABLE STRICT
AS $$
DECLARE
    a integer;
    b integer;
    c integer;
    d integer;
    e integer;
    m integer;
BEGIN
    a := jdn + 32044;
    b := (4 * a + 3) / 146097;
    c := a - (b * 146097) / 4;
    d := (4 * c + 3) / 1461;
    e := c - (1461 * d) / 4;
    m := (5 * e + 2) / 153;
    
    g_day := e - (153 * m + 2) / 5 + 1;
    g_month := m + 3 - 12 * (m / 10);
    g_year := b * 100 + d - 4800 + (m / 10);
    
    RETURN NEXT;
END;
$$;

COMMENT ON FUNCTION _jdn_to_gregorian(integer) IS
'Internal helper: Converts Julian Day Number to Gregorian date components.';

-- ============================================================================
-- Helper Function: Julian Day Number to Ethiopian
-- ============================================================================
CREATE OR REPLACE FUNCTION _jdn_to_ethiopian(jdn integer)
RETURNS TABLE(e_year integer, e_month integer, e_day integer)
LANGUAGE plpgsql
IMMUTABLE STRICT
AS $$
DECLARE
    ethiopian_epoch constant integer := 1724221;
    days_since_epoch integer;
    era integer;
    year_of_era integer;
    day_of_year integer;
    is_leap boolean;
    max_days integer;
BEGIN
    -- Calculate days since Ethiopian epoch
    days_since_epoch := jdn - ethiopian_epoch;
    
    -- Calculate era (4-year cycles)
    era := days_since_epoch / 1461;
    
    -- Calculate year within the era (0-3)
    year_of_era := (days_since_epoch % 1461) / 365;
    
    -- Calculate day of year (0-365)
    day_of_year := (days_since_epoch % 1461) % 365;
    
    -- Handle the 4th year of the era (leap year with 366 days)
    IF year_of_era = 4 THEN
        year_of_era := 3;
        day_of_year := 365;
    END IF;
    
    -- Calculate Ethiopian year
    e_year := 4 * era + year_of_era + 1;
    
    -- Calculate month and day
    IF day_of_year < 360 THEN
        -- Months 1-12: each has 30 days
        e_month := day_of_year / 30 + 1;
        e_day := (day_of_year % 30) + 1;
    ELSE
        -- Month 13 (Pagumē): 5 or 6 days
        e_month := 13;
        e_day := day_of_year - 360 + 1;
        
        -- Validate: month 13 has 5 days in regular years, 6 in leap years
        is_leap := (e_year % 4 = 3);
        max_days := CASE WHEN is_leap THEN 6 ELSE 5 END;
        
        IF e_day > max_days THEN
            e_day := max_days;
        END IF;
    END IF;
    
    RETURN NEXT;
END;
$$;

COMMENT ON FUNCTION _jdn_to_ethiopian(integer) IS
'Internal helper: Converts Julian Day Number to Ethiopian date components.';

-- ============================================================================
-- Helper Function: Ethiopian to Julian Day Number
-- ============================================================================
CREATE OR REPLACE FUNCTION _ethiopian_to_jdn(
    e_year integer,
    e_month integer,
    e_day integer
)
RETURNS integer
LANGUAGE plpgsql
IMMUTABLE STRICT
AS $$
DECLARE
    ethiopian_epoch constant integer := 1724221;
    era integer;
    year_of_era integer;
    day_of_year integer;
    jdn integer;
BEGIN
    -- Calculate era (4-year cycles) and year within era
    era := (e_year - 1) / 4;
    year_of_era := (e_year - 1) % 4;
    
    -- Calculate day of year (0-based)
    IF e_month <= 12 THEN
        -- Months 1-12: each has 30 days
        day_of_year := (e_month - 1) * 30 + (e_day - 1);
    ELSE
        -- Month 13 (Pagumē): days 360-365 (or 360-366 in leap years)
        day_of_year := 360 + (e_day - 1);
    END IF;
    
    -- Calculate Julian Day Number
    jdn := ethiopian_epoch + era * 1461 + year_of_era * 365 + day_of_year;
    
    RETURN jdn;
END;
$$;

COMMENT ON FUNCTION _ethiopian_to_jdn(integer, integer, integer) IS
'Internal helper: Converts Ethiopian date components to Julian Day Number.';

-- ============================================================================
-- Public Function: to_ethiopian_date(timestamp) → text
-- ============================================================================
-- Converts a Gregorian timestamp to Ethiopian calendar date string.
-- Returns format: 'YYYY-MM-DD'
-- The time component is discarded; only the date is converted.
-- ============================================================================
CREATE OR REPLACE FUNCTION to_ethiopian_date(ts timestamp)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE STRICT
AS $$
DECLARE
    g_year integer;
    g_month integer;
    g_day integer;
    jdn integer;
    eth record;
BEGIN
    -- Extract Gregorian date components
    g_year := EXTRACT(YEAR FROM ts)::integer;
    g_month := EXTRACT(MONTH FROM ts)::integer;
    g_day := EXTRACT(DAY FROM ts)::integer;
    
    -- Convert to Julian Day Number
    jdn := _gregorian_to_jdn(g_year, g_month, g_day);
    
    -- Convert to Ethiopian
    SELECT * INTO eth FROM _jdn_to_ethiopian(jdn);
    
    -- Format as YYYY-MM-DD
    RETURN to_char(eth.e_year, 'FM0000') || '-' || 
           to_char(eth.e_month, 'FM00') || '-' || 
           to_char(eth.e_day, 'FM00');
END;
$$;

COMMENT ON FUNCTION to_ethiopian_date(timestamp) IS
'Converts a Gregorian timestamp to Ethiopian calendar date string (format: YYYY-MM-DD). Time component is discarded.';

-- ============================================================================
-- Public Function: from_ethiopian_date(text) → timestamp
-- ============================================================================
-- Converts an Ethiopian calendar date string to Gregorian timestamp.
-- Input format: 'YYYY-MM-DD' (Ethiopian calendar)
-- Returns timestamp at midnight.
-- ============================================================================
CREATE OR REPLACE FUNCTION from_ethiopian_date(ethiopian_date text)
RETURNS timestamp
LANGUAGE plpgsql
IMMUTABLE STRICT
AS $$
DECLARE
    parts text[];
    e_year integer;
    e_month integer;
    e_day integer;
    jdn integer;
    greg record;
    is_leap boolean;
    max_days integer;
BEGIN
    -- Parse the Ethiopian date string
    parts := string_to_array(ethiopian_date, '-');
    
    IF array_length(parts, 1) != 3 THEN
        RAISE EXCEPTION 'Invalid Ethiopian date format: % (expected YYYY-MM-DD)', ethiopian_date;
    END IF;
    
    e_year := parts[1]::integer;
    e_month := parts[2]::integer;
    e_day := parts[3]::integer;
    
    -- Validate month
    IF e_month < 1 OR e_month > 13 THEN
        RAISE EXCEPTION 'Invalid Ethiopian month: % (must be 1-13)', e_month;
    END IF;
    
    -- Validate day
    IF e_day < 1 THEN
        RAISE EXCEPTION 'Invalid Ethiopian day: % (must be >= 1)', e_day;
    END IF;
    
    -- Validate day based on month
    IF e_month <= 12 THEN
        IF e_day > 30 THEN
            RAISE EXCEPTION 'Invalid Ethiopian day: % (month % has 30 days)', e_day, e_month;
        END IF;
    ELSE
        -- Month 13
        is_leap := (e_year % 4 = 3);
        max_days := CASE WHEN is_leap THEN 6 ELSE 5 END;
        IF e_day > max_days THEN
            RAISE EXCEPTION 'Invalid Ethiopian day: % (month 13 has % days in year %)', e_day, max_days, e_year;
        END IF;
    END IF;
    
    -- Convert to Julian Day Number
    jdn := _ethiopian_to_jdn(e_year, e_month, e_day);
    
    -- Convert to Gregorian
    SELECT * INTO greg FROM _jdn_to_gregorian(jdn);
    
    -- Return as timestamp at midnight
    RETURN make_timestamp(greg.g_year, greg.g_month, greg.g_day, 0, 0, 0);
END;
$$;

COMMENT ON FUNCTION from_ethiopian_date(text) IS
'Converts an Ethiopian calendar date string (format: YYYY-MM-DD) to Gregorian timestamp at midnight.';

-- ============================================================================
-- Public Function: to_ethiopian_timestamp(timestamp) → timestamp
-- ============================================================================
-- Converts a Gregorian timestamp to Ethiopian calendar timestamp.
-- The date is converted; the time-of-day is preserved.
-- Ideal for generated columns.
-- ============================================================================
CREATE OR REPLACE FUNCTION to_ethiopian_timestamp(ts timestamp)
RETURNS timestamp
LANGUAGE plpgsql
IMMUTABLE STRICT
AS $$
DECLARE
    g_year integer;
    g_month integer;
    g_day integer;
    jdn integer;
    eth record;
    time_part time;
BEGIN
    -- Extract Gregorian date components
    g_year := EXTRACT(YEAR FROM ts)::integer;
    g_month := EXTRACT(MONTH FROM ts)::integer;
    g_day := EXTRACT(DAY FROM ts)::integer;
    
    -- Extract time component
    time_part := ts::time;
    
    -- Convert to Julian Day Number
    jdn := _gregorian_to_jdn(g_year, g_month, g_day);
    
    -- Convert to Ethiopian
    SELECT * INTO eth FROM _jdn_to_ethiopian(jdn);
    
    -- Combine Ethiopian date with original time
    -- We use make_timestamp to create a timestamp with Ethiopian date values
    RETURN make_timestamp(
        eth.e_year,
        eth.e_month,
        eth.e_day,
        EXTRACT(HOUR FROM time_part)::integer,
        EXTRACT(MINUTE FROM time_part)::integer,
        EXTRACT(SECOND FROM time_part)
    );
END;
$$;

COMMENT ON FUNCTION to_ethiopian_timestamp(timestamp) IS
'Converts a Gregorian timestamp to Ethiopian calendar timestamp. Date is converted; time-of-day is preserved. Ideal for generated columns.';

-- ============================================================================
-- Public Function: to_ethiopian_datetime(timestamp) → timestamptz
-- ============================================================================
-- Converts a Gregorian timestamp to Ethiopian calendar timestamp with timezone.
-- ============================================================================
CREATE OR REPLACE FUNCTION to_ethiopian_datetime(ts timestamp)
RETURNS timestamp with time zone
LANGUAGE plpgsql
IMMUTABLE STRICT
AS $$
BEGIN
    RETURN to_ethiopian_timestamp(ts)::timestamp with time zone;
END;
$$;

COMMENT ON FUNCTION to_ethiopian_datetime(timestamp) IS
'Converts a Gregorian timestamp to Ethiopian calendar timestamp with time zone.';

-- ============================================================================
-- Public Function: current_ethiopian_date() → text
-- ============================================================================
-- Returns the current date in Ethiopian calendar.
-- This function is STABLE (not IMMUTABLE) because it depends on current time.
-- ============================================================================
CREATE OR REPLACE FUNCTION current_ethiopian_date()
RETURNS text
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    RETURN to_ethiopian_date(NOW()::timestamp);
END;
$$;

COMMENT ON FUNCTION current_ethiopian_date() IS
'Returns the current date in Ethiopian calendar (format: YYYY-MM-DD). STABLE function.';

-- ============================================================================
-- Aliases with pg_ prefix (PostgreSQL naming convention)
-- ============================================================================

CREATE OR REPLACE FUNCTION pg_ethiopian_to_date(ts timestamp)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE STRICT
AS $$
BEGIN
    RETURN to_ethiopian_date(ts);
END;
$$;

COMMENT ON FUNCTION pg_ethiopian_to_date(timestamp) IS
'Alias for to_ethiopian_date(). Converts Gregorian timestamp to Ethiopian date string.';

CREATE OR REPLACE FUNCTION pg_ethiopian_from_date(ethiopian_date text)
RETURNS timestamp
LANGUAGE plpgsql
IMMUTABLE STRICT
AS $$
BEGIN
    RETURN from_ethiopian_date(ethiopian_date);
END;
$$;

COMMENT ON FUNCTION pg_ethiopian_from_date(text) IS
'Alias for from_ethiopian_date(). Converts Ethiopian date string to Gregorian timestamp.';

CREATE OR REPLACE FUNCTION pg_ethiopian_to_timestamp(ts timestamp)
RETURNS timestamp
LANGUAGE plpgsql
IMMUTABLE STRICT
AS $$
BEGIN
    RETURN to_ethiopian_timestamp(ts);
END;
$$;

COMMENT ON FUNCTION pg_ethiopian_to_timestamp(timestamp) IS
'Alias for to_ethiopian_timestamp(). Converts Gregorian timestamp to Ethiopian timestamp.';

CREATE OR REPLACE FUNCTION pg_ethiopian_to_datetime(ts timestamp)
RETURNS timestamp with time zone
LANGUAGE plpgsql
IMMUTABLE STRICT
AS $$
BEGIN
    RETURN to_ethiopian_datetime(ts);
END;
$$;

COMMENT ON FUNCTION pg_ethiopian_to_datetime(timestamp) IS
'Alias for to_ethiopian_datetime(). Converts Gregorian timestamp to Ethiopian timestamp with timezone.';

-- ============================================================================
-- Usage Examples (as comments)
-- ============================================================================
-- 
-- Basic conversions:
--   SELECT to_ethiopian_date('2026-01-01'::timestamp);
--   -- Returns: '2018-04-23'
-- 
--   SELECT from_ethiopian_date('2018-04-23');
--   -- Returns: '2026-01-01 00:00:00'
-- 
--   SELECT current_ethiopian_date();
--   -- Returns: Current date in Ethiopian calendar
-- 
-- Generated columns:
--   CREATE TABLE orders (
--       id SERIAL PRIMARY KEY,
--       created_at TIMESTAMP DEFAULT NOW(),
--       created_at_ethiopian TIMESTAMP GENERATED ALWAYS AS 
--           (to_ethiopian_timestamp(created_at)) STORED
--   );
-- 
-- Functional indexes:
--   CREATE INDEX idx_orders_ethiopian 
--   ON orders (to_ethiopian_date(created_at));
-- 
-- ============================================================================

