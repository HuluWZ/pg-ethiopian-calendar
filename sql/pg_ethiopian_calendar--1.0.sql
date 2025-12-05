-- pg_ethiopian_calendar--1.0.sql
-- 
-- PostgreSQL extension for converting Gregorian timestamps to Ethiopian calendar dates.
-- 
-- Implementation based on formulas from:
--   Nachum Dershowitz & Edward M. Reingold,
--   "Calendrical Calculations", Cambridge University Press.
-- 
-- The Ethiopian calendar has:
--   - 13 months: 12 months of 30 days each, plus a 13th month of 5 or 6 days
--   - Year starts around September 11-12 in the Gregorian calendar
--   - Uses a different epoch than the Gregorian calendar

-- Function: to_ethiopian_date(timestamp)
-- 
-- Converts a Gregorian timestamp to an Ethiopian calendar date as text.
-- Returns the Ethiopian date in format: "YYYY-MM-DD"
-- The time component is discarded; only the date is converted.
-- 
-- Parameters:
--   timestamp: Gregorian calendar timestamp
-- 
-- Returns: TEXT (Ethiopian calendar date as string in format YYYY-MM-DD)
CREATE FUNCTION to_ethiopian_date(timestamp)
RETURNS text
AS 'MODULE_PATHNAME', 'to_ethiopian_date'
LANGUAGE C IMMUTABLE STRICT;

COMMENT ON FUNCTION to_ethiopian_date(timestamp) IS
'Converts a Gregorian timestamp to an Ethiopian calendar date as text (format: YYYY-MM-DD). The time component is discarded.';

-- Function: to_ethiopian_datetime(timestamp)
-- 
-- Converts a Gregorian timestamp to an Ethiopian calendar TIMESTAMP WITH TIME ZONE.
-- The date is converted to Ethiopian calendar; the time-of-day remains the same.
-- 
-- Parameters:
--   timestamp: Gregorian calendar timestamp
-- 
-- Returns: TIMESTAMP WITH TIME ZONE (date in Ethiopian calendar, time unchanged)
CREATE FUNCTION to_ethiopian_datetime(timestamp)
RETURNS timestamp with time zone
AS 'MODULE_PATHNAME', 'to_ethiopian_datetime'
LANGUAGE C IMMUTABLE STRICT;

COMMENT ON FUNCTION to_ethiopian_datetime(timestamp) IS
'Converts a Gregorian timestamp to an Ethiopian calendar TIMESTAMP WITH TIME ZONE. The date is converted to Ethiopian calendar; the time-of-day remains the same.';

-- Function: from_ethiopian_date(text)
-- 
-- Converts an Ethiopian calendar date string to a Gregorian timestamp.
-- The input should be in format "YYYY-MM-DD" (Ethiopian calendar).
-- 
-- Parameters:
--   ethiopian_date: Ethiopian calendar date as text (format: YYYY-MM-DD)
-- 
-- Returns: TIMESTAMP (Gregorian calendar timestamp at midnight)
CREATE FUNCTION from_ethiopian_date(text)
RETURNS timestamp
AS 'MODULE_PATHNAME', 'from_ethiopian_date'
LANGUAGE C IMMUTABLE STRICT;

COMMENT ON FUNCTION from_ethiopian_date(text) IS
'Converts an Ethiopian calendar date string to a Gregorian timestamp. Input format: YYYY-MM-DD (Ethiopian calendar). Returns timestamp at midnight.';

-- pg_ prefixed function aliases (PostgreSQL extension naming convention)
-- These provide the standard pg_ prefix while maintaining backward compatibility

-- Alias: pg_ethiopian_to_date (same as to_ethiopian_date)
CREATE FUNCTION pg_ethiopian_to_date(timestamp)
RETURNS text
AS 'MODULE_PATHNAME', 'to_ethiopian_date'
LANGUAGE C IMMUTABLE STRICT;

COMMENT ON FUNCTION pg_ethiopian_to_date(timestamp) IS
'Alias for to_ethiopian_date(). Converts a Gregorian timestamp to an Ethiopian calendar date as text (format: YYYY-MM-DD).';

-- Alias: pg_ethiopian_from_date (same as from_ethiopian_date)
CREATE FUNCTION pg_ethiopian_from_date(text)
RETURNS timestamp
AS 'MODULE_PATHNAME', 'from_ethiopian_date'
LANGUAGE C IMMUTABLE STRICT;

COMMENT ON FUNCTION pg_ethiopian_from_date(text) IS
'Alias for from_ethiopian_date(). Converts an Ethiopian calendar date string to a Gregorian timestamp. Input format: YYYY-MM-DD.';

-- Alias: pg_ethiopian_to_datetime (same as to_ethiopian_datetime)
CREATE FUNCTION pg_ethiopian_to_datetime(timestamp)
RETURNS timestamp with time zone
AS 'MODULE_PATHNAME', 'to_ethiopian_datetime'
LANGUAGE C IMMUTABLE STRICT;

COMMENT ON FUNCTION pg_ethiopian_to_datetime(timestamp) IS
'Alias for to_ethiopian_datetime(). Converts a Gregorian timestamp to an Ethiopian calendar TIMESTAMP WITH TIME ZONE. The date is converted to Ethiopian calendar; the time-of-day remains the same.';

