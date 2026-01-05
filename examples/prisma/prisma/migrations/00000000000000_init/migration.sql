-- Ethiopian Calendar Functions for PostgreSQL
-- Version: 1.1.1
-- Pure PL/pgSQL implementation - works with any PostgreSQL hosting

-- Helper: Gregorian to Julian Day Number
CREATE OR REPLACE FUNCTION _gregorian_to_jdn(g_year integer, g_month integer, g_day integer)
RETURNS integer
LANGUAGE plpgsql
IMMUTABLE STRICT
AS $$
DECLARE
    a integer;
    y integer;
    m integer;
BEGIN
    a := (14 - g_month) / 12;
    y := g_year + 4800 - a;
    m := g_month + 12 * a - 3;
    RETURN g_day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045;
END;
$$;

-- Helper: Julian Day Number to Ethiopian
CREATE OR REPLACE FUNCTION _jdn_to_ethiopian(jdn integer)
RETURNS integer[]
LANGUAGE plpgsql
IMMUTABLE STRICT
AS $$
DECLARE
    r integer;
    n integer;
    e_year integer;
    e_month integer;
    e_day integer;
BEGIN
    r := (jdn - 1723856) MOD 1461;
    n := (r MOD 365) + 365 * (r / 1460);
    e_year := 4 * ((jdn - 1723856) / 1461) + r / 365 - r / 1460;
    e_month := n / 30 + 1;
    e_day := (n MOD 30) + 1;
    RETURN ARRAY[e_year, e_month, e_day];
END;
$$;

-- Helper: Ethiopian to Julian Day Number (with validation)
CREATE OR REPLACE FUNCTION _ethiopian_to_jdn(e_year integer, e_month integer, e_day integer)
RETURNS integer
LANGUAGE plpgsql
IMMUTABLE STRICT
AS $$
DECLARE
    is_leap boolean;
    max_days integer;
BEGIN
    IF e_year < 1 THEN
        RAISE EXCEPTION 'Invalid Ethiopian year: % (must be >= 1)', e_year
            USING ERRCODE = 'datetime_field_overflow';
    END IF;
    IF e_month < 1 OR e_month > 13 THEN
        RAISE EXCEPTION 'Invalid Ethiopian month: % (must be 1-13)', e_month
            USING ERRCODE = 'datetime_field_overflow';
    END IF;
    IF e_day < 1 THEN
        RAISE EXCEPTION 'Invalid Ethiopian day: % (must be >= 1)', e_day
            USING ERRCODE = 'datetime_field_overflow';
    END IF;
    IF e_month <= 12 THEN
        IF e_day > 30 THEN
            RAISE EXCEPTION 'Invalid Ethiopian day: % (month % has 30 days)', e_day, e_month
                USING ERRCODE = 'datetime_field_overflow';
        END IF;
    ELSE
        is_leap := (e_year % 4 = 3);
        max_days := CASE WHEN is_leap THEN 6 ELSE 5 END;
        IF e_day > max_days THEN
            RAISE EXCEPTION 'Invalid Ethiopian day: % (month 13 has % days in year %)', e_day, max_days, e_year
                USING ERRCODE = 'datetime_field_overflow';
        END IF;
    END IF;
    RETURN 1723856 + 365 * e_year + e_year / 4 + 30 * (e_month - 1) + e_day - 1;
END;
$$;

-- Convert Gregorian date/timestamp to Ethiopian date string
CREATE OR REPLACE FUNCTION to_ethiopian_date(ts timestamp)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE STRICT
AS $$
DECLARE
    jdn integer;
    eth integer[];
BEGIN
    jdn := _gregorian_to_jdn(
        EXTRACT(YEAR FROM ts)::integer,
        EXTRACT(MONTH FROM ts)::integer,
        EXTRACT(DAY FROM ts)::integer
    );
    eth := _jdn_to_ethiopian(jdn);
    RETURN eth[1]::text || '-' || LPAD(eth[2]::text, 2, '0') || '-' || LPAD(eth[3]::text, 2, '0');
END;
$$;

-- Overload: Get current Ethiopian date
CREATE OR REPLACE FUNCTION to_ethiopian_date()
RETURNS text
LANGUAGE sql
STABLE
AS $$
    SELECT to_ethiopian_date(NOW()::timestamp);
$$;

-- Convert Gregorian timestamp to Ethiopian timestamp string
CREATE OR REPLACE FUNCTION to_ethiopian_timestamp(ts timestamp)
RETURNS timestamp
LANGUAGE plpgsql
IMMUTABLE STRICT
AS $$
DECLARE
    jdn integer;
    eth integer[];
    time_part text;
BEGIN
    jdn := _gregorian_to_jdn(
        EXTRACT(YEAR FROM ts)::integer,
        EXTRACT(MONTH FROM ts)::integer,
        EXTRACT(DAY FROM ts)::integer
    );
    eth := _jdn_to_ethiopian(jdn);
    time_part := TO_CHAR(ts, 'HH24:MI:SS.US');
    RETURN (eth[1]::text || '-' || LPAD(eth[2]::text, 2, '0') || '-' || LPAD(eth[3]::text, 2, '0') || ' ' || time_part)::timestamp;
END;
$$;

-- Overload: Get current Ethiopian timestamp
CREATE OR REPLACE FUNCTION to_ethiopian_timestamp()
RETURNS timestamp
LANGUAGE sql
STABLE
AS $$
    SELECT to_ethiopian_timestamp(NOW()::timestamp);
$$;

-- Convert Ethiopian date string to Gregorian date
CREATE OR REPLACE FUNCTION from_ethiopian_date(ethiopian_date text)
RETURNS date
LANGUAGE plpgsql
IMMUTABLE STRICT
AS $$
DECLARE
    parts text[];
    e_year integer;
    e_month integer;
    e_day integer;
    jdn integer;
    a integer;
    b integer;
    c integer;
    d integer;
    e integer;
    m integer;
    g_day integer;
    g_month integer;
    g_year integer;
BEGIN
    parts := string_to_array(ethiopian_date, '-');
    IF array_length(parts, 1) != 3 THEN
        RAISE EXCEPTION 'Invalid Ethiopian date format: % (expected YYYY-MM-DD)', ethiopian_date
            USING ERRCODE = 'invalid_datetime_format';
    END IF;
    e_year := parts[1]::integer;
    e_month := parts[2]::integer;
    e_day := parts[3]::integer;
    jdn := _ethiopian_to_jdn(e_year, e_month, e_day);
    a := jdn + 32044;
    b := (4 * a + 3) / 146097;
    c := a - (146097 * b / 4);
    d := (4 * c + 3) / 1461;
    e := c - (1461 * d / 4);
    m := (5 * e + 2) / 153;
    g_day := e - (153 * m + 2) / 5 + 1;
    g_month := m + 3 - 12 * (m / 10);
    g_year := 100 * b + d - 4800 + m / 10;
    RETURN make_date(g_year, g_month, g_day);
END;
$$;

-- Get current Ethiopian date
CREATE OR REPLACE FUNCTION current_ethiopian_date()
RETURNS text
LANGUAGE sql
STABLE
AS $$
    SELECT to_ethiopian_date(NOW()::timestamp);
$$;

-- Get version
CREATE OR REPLACE FUNCTION ethiopian_calendar_version()
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT '1.1.1'::text;
$$;

-- Aliases for compatibility
CREATE OR REPLACE FUNCTION pg_to_ethiopian(ts timestamp) RETURNS text LANGUAGE sql IMMUTABLE AS $$ SELECT to_ethiopian_date(ts); $$;
CREATE OR REPLACE FUNCTION pg_from_ethiopian(ethiopian_date text) RETURNS date LANGUAGE sql IMMUTABLE AS $$ SELECT from_ethiopian_date(ethiopian_date); $$;

-- ============================================================================
-- Tables
-- ============================================================================

CREATE TABLE "customers" (
    "id" SERIAL PRIMARY KEY,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL UNIQUE,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "orders" (
    "id" SERIAL PRIMARY KEY,
    "order_number" TEXT NOT NULL UNIQUE,
    "customer_id" INTEGER NOT NULL REFERENCES "customers"("id"),
    "total_amount" DECIMAL(10,2) NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at_ethiopian" TIMESTAMP GENERATED ALWAYS AS (to_ethiopian_timestamp("created_at"::timestamp)) STORED,
    "updated_at_ethiopian" TIMESTAMP GENERATED ALWAYS AS (to_ethiopian_timestamp("updated_at"::timestamp)) STORED
);

CREATE TABLE "order_items" (
    "id" SERIAL PRIMARY KEY,
    "order_id" INTEGER NOT NULL REFERENCES "orders"("id") ON DELETE CASCADE,
    "product" TEXT NOT NULL,
    "quantity" INTEGER NOT NULL,
    "price" DECIMAL(10,2) NOT NULL
);

CREATE TABLE "events" (
    "id" SERIAL PRIMARY KEY,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "event_date" TIMESTAMP(3) NOT NULL,
    "event_date_ethiopian" TIMESTAMP GENERATED ALWAYS AS (to_ethiopian_timestamp("event_date"::timestamp)) STORED,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at_ethiopian" TIMESTAMP GENERATED ALWAYS AS (to_ethiopian_timestamp("created_at"::timestamp)) STORED
);

-- Indexes for Ethiopian date queries
CREATE INDEX "idx_orders_created_ethiopian" ON "orders"("created_at_ethiopian");
CREATE INDEX "idx_events_date_ethiopian" ON "events"("event_date_ethiopian");

