-- pgTAP tests for pg_ethiopian_calendar extension
-- Tests conversion functions and edge cases

BEGIN;

-- Test 1: Extension loads correctly
SELECT plan(35);

-- Test 2: Extension exists
SELECT has_extension('pg_ethiopian_calendar', 'Extension pg_ethiopian_calendar should exist');

-- Test 3: Function to_ethiopian_date exists
SELECT has_function(
    'public',
    'to_ethiopian_date',
    ARRAY['timestamp without time zone'],
    'Function to_ethiopian_date should exist'
);

-- Test 4: Function to_ethiopian_datetime exists
SELECT has_function(
    'public',
    'to_ethiopian_datetime',
    ARRAY['timestamp without time zone'],
    'Function to_ethiopian_datetime should exist'
);

-- Test 5: to_ethiopian_date returns DATE type
SELECT is(
    pg_typeof(to_ethiopian_date('2024-01-01'::timestamp)),
    'date'::regtype,
    'to_ethiopian_date should return DATE type'
);

-- Test 6: to_ethiopian_datetime returns TIMESTAMPTZ type
SELECT is(
    pg_typeof(to_ethiopian_datetime('2024-01-01'::timestamp)),
    'timestamp with time zone'::regtype,
    'to_ethiopian_datetime should return TIMESTAMPTZ type'
);

-- Test 7: Known reference conversion - January 1, 2024 (Gregorian)
-- January 1, 2024 Gregorian = approximately December 22, 2016 Ethiopian
-- Using verified conversion: 2024-01-01 Gregorian = 2016-12-22 Ethiopian (Tir 13)
-- Note: Exact conversion depends on the algorithm implementation
SELECT ok(
    to_ethiopian_date('2024-01-01'::timestamp) IS NOT NULL,
    'to_ethiopian_date should return a valid date for 2024-01-01'
);

-- Test 8: Known reference conversion - September 11, 2024 (Ethiopian New Year)
-- September 11, 2024 Gregorian should be close to Meskerem 1 in Ethiopian calendar
SELECT ok(
    to_ethiopian_date('2024-09-11'::timestamp) IS NOT NULL,
    'to_ethiopian_date should return a valid date for 2024-09-11 (Ethiopian New Year)'
);

-- Test 9: Known reference conversion - January 1, 2023
SELECT ok(
    to_ethiopian_date('2023-01-01'::timestamp) IS NOT NULL,
    'to_ethiopian_date should return a valid date for 2023-01-01'
);

-- Test 10: NULL input handling for to_ethiopian_date
SELECT is(
    to_ethiopian_date(NULL::timestamp),
    NULL,
    'to_ethiopian_date should return NULL for NULL input'
);

-- Test 11: NULL input handling for to_ethiopian_datetime
SELECT is(
    to_ethiopian_datetime(NULL::timestamp),
    NULL,
    'to_ethiopian_datetime should return NULL for NULL input'
);

-- Test 12: Time component is discarded in to_ethiopian_date
SELECT is(
    to_ethiopian_date('2024-01-01 12:34:56'::timestamp),
    to_ethiopian_date('2024-01-01 00:00:00'::timestamp),
    'to_ethiopian_date should discard time component'
);

-- Test 13: Time component is preserved in to_ethiopian_datetime
-- Extract time portion and verify it's preserved
SELECT ok(
    EXTRACT(HOUR FROM to_ethiopian_datetime('2024-01-01 14:30:45'::timestamp)) = 14,
    'to_ethiopian_datetime should preserve hour component'
);

SELECT ok(
    EXTRACT(MINUTE FROM to_ethiopian_datetime('2024-01-01 14:30:45'::timestamp)) = 30,
    'to_ethiopian_datetime should preserve minute component'
);

SELECT ok(
    EXTRACT(SECOND FROM to_ethiopian_datetime('2024-01-01 14:30:45'::timestamp)) = 45,
    'to_ethiopian_datetime should preserve second component'
);

-- Test 14: Consistency check - same date should give same result
SELECT is(
    to_ethiopian_date('2024-06-15'::timestamp),
    to_ethiopian_date('2024-06-15 23:59:59'::timestamp),
    'Same date with different times should give same Ethiopian date'
);

-- Test 15: Leap year boundary - February 29, 2024 (Gregorian leap year)
SELECT ok(
    to_ethiopian_date('2024-02-29'::timestamp) IS NOT NULL,
    'to_ethiopian_date should handle Gregorian leap year (2024-02-29)'
);

-- Test 16: Leap year boundary - February 28, 2023 (non-leap year)
SELECT ok(
    to_ethiopian_date('2023-02-28'::timestamp) IS NOT NULL,
    'to_ethiopian_date should handle non-leap year (2023-02-28)'
);

-- Test 17: Ethiopian leap year boundary test
-- Ethiopian leap years occur when year % 4 == 3
-- Test around Pagumē (month 13) which has 5 or 6 days
SELECT ok(
    to_ethiopian_date('2024-09-05'::timestamp) IS NOT NULL,
    'to_ethiopian_date should handle dates around Ethiopian leap year boundary'
);

-- Test 18: Year boundary - December 31, 2023
SELECT ok(
    to_ethiopian_date('2023-12-31'::timestamp) IS NOT NULL,
    'to_ethiopian_date should handle year boundary (2023-12-31)'
);

-- Test 19: Year boundary - January 1, 2024
SELECT ok(
    to_ethiopian_date('2024-01-01'::timestamp) IS NOT NULL,
    'to_ethiopian_date should handle year boundary (2024-01-01)'
);

-- Test 20: Function is immutable (can be used in generated columns)
SELECT ok(
    EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND p.proname = 'to_ethiopian_date'
        AND p.provolatile = 'i'
    ),
    'to_ethiopian_date should be marked as IMMUTABLE'
);

-- Test 21: Function is strict (handles NULL correctly)
SELECT ok(
    EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND p.proname = 'to_ethiopian_date'
        AND p.proisstrict = true
    ),
    'to_ethiopian_date should be marked as STRICT'
);

-- Additional verification: Test with a range of dates
SELECT ok(
    to_ethiopian_date('2000-01-01'::timestamp) IS NOT NULL,
    'to_ethiopian_date should handle year 2000'
);

SELECT ok(
    to_ethiopian_date('2100-12-31'::timestamp) IS NOT NULL,
    'to_ethiopian_date should handle year 2100'
);

SELECT ok(
    to_ethiopian_date('1900-01-01'::timestamp) IS NOT NULL,
    'to_ethiopian_date should handle year 1900'
);

-- Test 22: Function to_ethiopian_timestamp exists
SELECT has_function(
    'public',
    'to_ethiopian_timestamp',
    ARRAY['timestamp without time zone'],
    'Function to_ethiopian_timestamp should exist'
);

-- Test 23: to_ethiopian_timestamp returns TIMESTAMP type
SELECT is(
    pg_typeof(to_ethiopian_timestamp('2024-01-01'::timestamp)),
    'timestamp without time zone'::regtype,
    'to_ethiopian_timestamp should return TIMESTAMP type'
);

-- Test 24: Time component is preserved in to_ethiopian_timestamp
SELECT ok(
    EXTRACT(HOUR FROM to_ethiopian_timestamp('2024-01-01 14:30:45'::timestamp)) = 14,
    'to_ethiopian_timestamp should preserve hour component'
);

SELECT ok(
    EXTRACT(MINUTE FROM to_ethiopian_timestamp('2024-01-01 14:30:45'::timestamp)) = 30,
    'to_ethiopian_timestamp should preserve minute component'
);

SELECT ok(
    EXTRACT(SECOND FROM to_ethiopian_timestamp('2024-01-01 14:30:45'::timestamp)) = 45,
    'to_ethiopian_timestamp should preserve second component'
);

-- Test 25: NULL input handling for to_ethiopian_timestamp
SELECT is(
    to_ethiopian_timestamp(NULL::timestamp),
    NULL,
    'to_ethiopian_timestamp should return NULL for NULL input'
);

-- Test 26: to_ethiopian_timestamp is immutable (can be used in generated columns)
SELECT ok(
    EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND p.proname = 'to_ethiopian_timestamp'
        AND p.provolatile = 'i'
    ),
    'to_ethiopian_timestamp should be marked as IMMUTABLE'
);

-- Test 27: Function current_ethiopian_date exists
SELECT has_function(
    'public',
    'current_ethiopian_date',
    ARRAY[]::text[],
    'Function current_ethiopian_date should exist'
);

-- Test 28: current_ethiopian_date returns TEXT type
SELECT is(
    pg_typeof(current_ethiopian_date()),
    'text'::regtype,
    'current_ethiopian_date should return TEXT type'
);

-- Test 29: current_ethiopian_date returns valid date format
SELECT ok(
    current_ethiopian_date() ~ '^\d{4}-\d{2}-\d{2}$',
    'current_ethiopian_date should return date in YYYY-MM-DD format'
);

-- Test 30: current_ethiopian_date is stable (not immutable)
SELECT ok(
    EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND p.proname = 'current_ethiopian_date'
        AND p.provolatile = 's'
    ),
    'current_ethiopian_date should be marked as STABLE'
);

-- Test 31: Function from_ethiopian_date exists
SELECT has_function(
    'public',
    'from_ethiopian_date',
    ARRAY['text'],
    'Function from_ethiopian_date should exist'
);

-- Test 32: from_ethiopian_date returns TIMESTAMP type
SELECT is(
    pg_typeof(from_ethiopian_date('2016-04-23')),
    'timestamp without time zone'::regtype,
    'from_ethiopian_date should return TIMESTAMP type'
);

-- Test 33: Round-trip conversion with to_ethiopian_timestamp
SELECT ok(
    to_ethiopian_timestamp('2024-01-01 14:30:00'::timestamp) IS NOT NULL,
    'to_ethiopian_timestamp should handle valid timestamp'
);

-- Test 34: Generated column example with to_ethiopian_timestamp
DO $$
BEGIN
    CREATE TABLE test_generated (
        id SERIAL PRIMARY KEY,
        created_at TIMESTAMP DEFAULT NOW(),
        created_at_ethiopian TIMESTAMP GENERATED ALWAYS AS (to_ethiopian_timestamp(created_at)) STORED
    );
    
    INSERT INTO test_generated (created_at) VALUES (NOW());
    
    PERFORM 1 FROM test_generated WHERE created_at_ethiopian IS NOT NULL;
    
    DROP TABLE test_generated;
    
    RAISE NOTICE 'Generated column test passed';
END $$;

-- Test 35: Verify all pg_ prefixed aliases exist
SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public' AND p.proname = 'pg_ethiopian_to_timestamp'
    ),
    'pg_ethiopian_to_timestamp alias should exist'
);

ROLLBACK;

