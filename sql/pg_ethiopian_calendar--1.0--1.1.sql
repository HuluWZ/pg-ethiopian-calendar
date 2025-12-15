-- pg_ethiopian_calendar--1.0--1.1.sql
-- 
-- Migration script from version 1.0 to 1.1
-- Adds new functions: current_ethiopian_date, to_ethiopian_timestamp

-- Function: current_ethiopian_date()
-- 
-- Returns the current date in Ethiopian calendar as text.
-- This function is STABLE (not IMMUTABLE) because it depends on the current time.
-- Useful for DEFAULT values and queries that need the current Ethiopian date.
-- 
-- Returns: TEXT (current Ethiopian calendar date as string in format YYYY-MM-DD)
CREATE FUNCTION current_ethiopian_date()
RETURNS text
AS 'MODULE_PATHNAME', 'current_ethiopian_date'
LANGUAGE C STABLE;

COMMENT ON FUNCTION current_ethiopian_date() IS
'Returns the current date in Ethiopian calendar as text (format: YYYY-MM-DD). This function is STABLE because it depends on the current time. Useful for DEFAULT values and generated columns.';

-- Function: to_ethiopian_timestamp(timestamp)
-- 
-- Converts a Gregorian timestamp to an Ethiopian calendar TIMESTAMP.
-- The date is converted to Ethiopian calendar; the time-of-day remains the same.
-- This function returns TIMESTAMP (without time zone) for use in generated columns.
-- 
-- Parameters:
--   timestamp: Gregorian calendar timestamp
-- 
-- Returns: TIMESTAMP (Ethiopian calendar date with original time preserved)
CREATE FUNCTION to_ethiopian_timestamp(timestamp)
RETURNS timestamp
AS 'MODULE_PATHNAME', 'to_ethiopian_timestamp'
LANGUAGE C IMMUTABLE STRICT;

COMMENT ON FUNCTION to_ethiopian_timestamp(timestamp) IS
'Converts a Gregorian timestamp to an Ethiopian calendar TIMESTAMP. The date is converted to Ethiopian calendar; the time-of-day remains the same. Returns TIMESTAMP (without time zone) for use in generated columns.';

-- Alias: pg_ethiopian_to_timestamp (same as to_ethiopian_timestamp)
CREATE FUNCTION pg_ethiopian_to_timestamp(timestamp)
RETURNS timestamp
AS 'MODULE_PATHNAME', 'to_ethiopian_timestamp'
LANGUAGE C IMMUTABLE STRICT;

COMMENT ON FUNCTION pg_ethiopian_to_timestamp(timestamp) IS
'Alias for to_ethiopian_timestamp(). Converts a Gregorian timestamp to an Ethiopian calendar TIMESTAMP. The date is converted to Ethiopian calendar; the time-of-day remains the same.';

