# Testing Guide: Ethiopian Calendar Extension

This guide shows you how to run and test the PostgreSQL Ethiopian calendar extension functions.

## Quick Start

### 1. Start the PostgreSQL Container

```bash
# Start with default PostgreSQL 14
make docker-start

# Or specify a different PostgreSQL version
PG_VERSION=16 make docker-start
```

### 2. Connect to the Database

```bash
# Interactive psql session
make docker-shell

# Or use docker compose directly
docker compose exec postgres psql -U postgres
```

### 3. Create the Extension

**Important:** The extension must be created manually. Once connected to psql:

```sql
CREATE EXTENSION pg_ethiopian_calendar;
```

### 4. Test the Functions

## Manual Testing Examples

### Test 1: Convert Gregorian to Ethiopian Date

```sql
-- Basic conversion
SELECT to_ethiopian_date('2024-01-01'::timestamp);
-- Expected: 2016-04-23

-- Using pg_ prefixed alias
SELECT pg_ethiopian_to_date('2024-01-01'::timestamp);
-- Expected: 2016-04-23

-- With time component (time is discarded)
SELECT to_ethiopian_date('2024-01-01 14:30:00'::timestamp);
-- Expected: 2016-04-23
```

### Test 2: Convert Ethiopian to Gregorian Date

```sql
-- Convert Ethiopian date to Gregorian timestamp
SELECT from_ethiopian_date('2016-04-23');
-- Expected: 2024-01-01 00:00:00

-- Using pg_ prefixed alias
SELECT pg_ethiopian_from_date('2016-04-23');
-- Expected: 2024-01-01 00:00:00

-- Test Ethiopian New Year (Meskerem 1)
SELECT from_ethiopian_date('2016-01-01');
-- Expected: 2023-09-11 00:00:00
```

### Test 3: Convert with Time Component Preserved

```sql
-- Convert date but preserve time
SELECT to_ethiopian_datetime('2024-01-01 14:30:45'::timestamp);
-- Expected: Date converted, time preserved

-- Using pg_ prefixed alias
SELECT pg_ethiopian_to_datetime('2024-01-01 14:30:45'::timestamp);
```

### Test 4: Round-Trip Conversion

```sql
-- Convert Gregorian → Ethiopian → Gregorian
SELECT 
    '2024-01-01'::timestamp AS original,
    to_ethiopian_date('2024-01-01'::timestamp) AS ethiopian,
    from_ethiopian_date(to_ethiopian_date('2024-01-01'::timestamp)) AS back_to_gregorian;
```

### Test 5: List All Available Functions

```sql
-- Show all extension functions
SELECT 
    proname AS function_name,
    pg_get_function_arguments(oid) AS arguments,
    pg_get_function_result(oid) AS return_type
FROM pg_proc 
WHERE proname LIKE '%ethiopian%'
ORDER BY proname;
```

### Test 6: Verify Extension Version

```sql
-- Check extension version
SELECT extname, extversion FROM pg_extension WHERE extname = 'pg_ethiopian_calendar';
-- Expected: pg_ethiopian_calendar | 1.0
```

### Test 7: Test Edge Cases

```sql
-- NULL handling
SELECT to_ethiopian_date(NULL::timestamp);
-- Expected: NULL

SELECT from_ethiopian_date(NULL);
-- Expected: NULL

-- Ethiopian leap year (Pagumē has 6 days)
SELECT from_ethiopian_date('2015-13-06');  -- Leap year
SELECT from_ethiopian_date('2016-13-05');  -- Non-leap year

-- Year boundaries
SELECT to_ethiopian_date('2023-12-31'::timestamp);
SELECT to_ethiopian_date('2024-01-01'::timestamp);
```

### Test 8: Compare Original and pg_ Prefixed Functions

```sql
-- Verify they return the same results
SELECT 
    to_ethiopian_date('2024-01-01'::timestamp) = 
    pg_ethiopian_to_date('2024-01-01'::timestamp) AS functions_match;
-- Expected: true

SELECT 
    from_ethiopian_date('2016-04-23') = 
    pg_ethiopian_from_date('2016-04-23') AS functions_match;
-- Expected: true
```

## Running Automated Tests

### Option 1: Using Makefile (Recommended)

```bash
# Run all tests
make docker-test

# Run tests for specific PostgreSQL version
PG_VERSION=16 make docker-test
```

### Option 2: Using Docker Compose Directly

```bash
# Run test container
docker compose run --rm test

# Or with specific PostgreSQL version
PG_VERSION=16 docker compose run --rm test
```

### Option 3: Run Tests Manually

```bash
# Connect to test database
docker compose exec test psql -U postgres -d test_db

# Then run test SQL file
\i /app/test/tests/ethiopian_calendar_tests.sql
```

## Testing from Command Line (Non-Interactive)

### Quick Function Test

```bash
# Test to_ethiopian_date
docker compose exec -T postgres psql -U postgres -c \
  "SELECT to_ethiopian_date('2024-01-01'::timestamp);"

# Test from_ethiopian_date
docker compose exec -T postgres psql -U postgres -c \
  "SELECT from_ethiopian_date('2016-04-23');"

# Test pg_ prefixed functions
docker compose exec -T postgres psql -U postgres -c \
  "SELECT pg_ethiopian_to_date('2024-01-01'::timestamp);"
```

### Run Multiple Tests

```bash
docker compose exec -T postgres psql -U postgres << 'EOF'
CREATE EXTENSION IF NOT EXISTS ethiopian_calendar;

-- Test all functions
SELECT 'to_ethiopian_date' AS test, to_ethiopian_date('2024-01-01'::timestamp) AS result
UNION ALL
SELECT 'from_ethiopian_date', from_ethiopian_date('2016-04-23')::text
UNION ALL
SELECT 'pg_ethiopian_to_date', pg_ethiopian_to_date('2024-01-01'::timestamp)
UNION ALL
SELECT 'pg_ethiopian_from_date', pg_ethiopian_from_date('2016-04-23')::text;
EOF
```

## Common Test Scenarios

### Scenario 1: Date Conversion Table

```sql
-- Create a table with sample dates
CREATE TABLE test_dates (
    id SERIAL PRIMARY KEY,
    gregorian_date DATE,
    ethiopian_date TEXT
);

-- Insert sample dates
INSERT INTO test_dates (gregorian_date) VALUES
    ('2024-01-01'),
    ('2024-09-11'),  -- Ethiopian New Year
    ('2024-12-25');  -- Christmas

-- Convert all dates
UPDATE test_dates 
SET ethiopian_date = to_ethiopian_date(gregorian_date::timestamp);

-- View results
SELECT * FROM test_dates;
```

### Scenario 2: Query by Ethiopian Date

```sql
-- Find records matching an Ethiopian date
SELECT *
FROM test_dates
WHERE to_ethiopian_date(gregorian_date::timestamp) = '2016-04-23';
```

### Scenario 3: Date Range Conversion

```sql
-- Convert a date range
SELECT 
    generate_series('2024-01-01'::date, '2024-01-07'::date, '1 day'::interval) AS gregorian_date,
    to_ethiopian_date(generate_series('2024-01-01'::date, '2024-01-07'::date, '1 day'::interval)::timestamp) AS ethiopian_date;
```

## Troubleshooting

### Container Not Running

```bash
# Check container status
make docker-status

# Or
docker compose ps
```

### Extension Not Found

```bash
# Verify extension is installed
docker compose exec -T postgres psql -U postgres -c \
  "SELECT * FROM pg_extension WHERE extname = 'pg_ethiopian_calendar';"

# If not found, create it
docker compose exec -T postgres psql -U postgres -c \
  "CREATE EXTENSION pg_ethiopian_calendar;"
```

### Function Errors

```bash
# Check function definitions
docker compose exec -T postgres psql -U postgres -c \
  "SELECT proname, pg_get_function_arguments(oid) FROM pg_proc WHERE proname LIKE '%ethiopian%';"
```

### View Logs

```bash
# View PostgreSQL logs
make docker-logs

# Or
docker compose logs postgres
```

## Performance Testing

```sql
-- Test performance with large dataset
EXPLAIN ANALYZE
SELECT to_ethiopian_date(generate_series('2000-01-01'::date, '2100-12-31'::date, '1 day'::interval)::timestamp);
```

## Next Steps

- See `README.md` for detailed function documentation
- See `DOCKER.md` for Docker-specific instructions
- See `EXTENSION_STANDARDS.md` for extension standards information

