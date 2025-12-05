# Quick Start: Testing with Your Own Dates

## Step 1: Start the Database

```bash
# Start PostgreSQL container
make docker-start

# Or with a specific PostgreSQL version
PG_VERSION=16 make docker-start
```

## Step 2: Connect to Database

```bash
# Interactive psql session
make docker-shell

# Or one-line command
docker compose exec postgres psql -U postgres
```

## Step 3: Create Extension

**Important:** The extension must be created manually. Once in psql:

```sql
CREATE EXTENSION pg_ethiopian_calendar;
```

This only needs to be done once per database. The extension will be available for all subsequent connections.

## Step 4: Test with Your Own Dates

### Convert Gregorian → Ethiopian

```sql
-- Replace with your own date
SELECT to_ethiopian_date('2024-12-25'::timestamp) AS ethiopian_date;

-- Or with time (time is discarded)
SELECT to_ethiopian_date('2024-12-25 14:30:00'::timestamp) AS ethiopian_date;

-- Using pg_ prefixed function
SELECT pg_ethiopian_to_date('2024-12-25'::timestamp) AS ethiopian_date;
```

### Convert Ethiopian → Gregorian

```sql
-- Replace with your own Ethiopian date (format: YYYY-MM-DD)
SELECT from_ethiopian_date('2016-08-15') AS gregorian_date;

-- Using pg_ prefixed function
SELECT pg_ethiopian_from_date('2016-08-15') AS gregorian_date;
```

### Round-Trip Test

```sql
-- Convert your date: Gregorian → Ethiopian → Gregorian
SELECT 
    '2024-12-25'::timestamp AS original,
    to_ethiopian_date('2024-12-25'::timestamp) AS to_ethiopian,
    from_ethiopian_date(to_ethiopian_date('2024-12-25'::timestamp)) AS back_to_gregorian;
```

## Examples with Multiple Dates

### Test Multiple Dates at Once

```sql
-- Create a table with your dates
CREATE TABLE my_dates (
    id SERIAL PRIMARY KEY,
    gregorian_date DATE,
    ethiopian_date TEXT
);

-- Insert your dates
INSERT INTO my_dates (gregorian_date) VALUES
    ('2024-01-01'),
    ('2024-06-15'),
    ('2024-12-25'),
    ('2025-01-01');

-- Convert all dates
UPDATE my_dates 
SET ethiopian_date = to_ethiopian_date(gregorian_date::timestamp);

-- View results
SELECT 
    gregorian_date,
    ethiopian_date,
    from_ethiopian_date(ethiopian_date) AS back_to_gregorian
FROM my_dates;
```

### Date Range Conversion

```sql
-- Convert a range of dates
SELECT 
    generate_series('2024-01-01'::date, '2024-01-07'::date, '1 day'::interval)::date AS gregorian,
    to_ethiopian_date(generate_series('2024-01-01'::date, '2024-01-07'::date, '1 day'::interval)::timestamp) AS ethiopian;
```

## Quick Command-Line Testing

### Single Date Test (Non-Interactive)

```bash
# Test one date
docker compose exec -T postgres psql -U postgres << 'EOF'
CREATE EXTENSION IF NOT EXISTS pg_ethiopian_calendar;
SELECT to_ethiopian_date('2024-12-25'::timestamp) AS ethiopian_date;
EOF
```

### Multiple Dates Test

```bash
# Test multiple dates
docker compose exec -T postgres psql -U postgres << 'EOF'
CREATE EXTENSION IF NOT EXISTS pg_ethiopian_calendar;

SELECT 
    '2024-01-01'::date AS gregorian,
    to_ethiopian_date('2024-01-01'::timestamp) AS ethiopian
UNION ALL
SELECT 
    '2024-06-15'::date,
    to_ethiopian_date('2024-06-15'::timestamp)
UNION ALL
SELECT 
    '2024-12-25'::date,
    to_ethiopian_date('2024-12-25'::timestamp);
EOF
```

## Common Use Cases

### Find Today's Ethiopian Date

```sql
SELECT 
    CURRENT_DATE AS today_gregorian,
    to_ethiopian_date(CURRENT_DATE::timestamp) AS today_ethiopian;
```

### Find Ethiopian New Year (Meskerem 1)

```sql
-- Ethiopian New Year is around September 11-12 in Gregorian
SELECT 
    '2024-09-11'::date AS gregorian,
    to_ethiopian_date('2024-09-11'::timestamp) AS ethiopian;
```

### Convert Specific Ethiopian Date

```sql
-- Example: Ethiopian date 2016-04-23
SELECT 
    '2016-04-23' AS ethiopian_date,
    from_ethiopian_date('2016-04-23') AS gregorian_equivalent;
```

### Query by Ethiopian Date

```sql
-- Find records matching a specific Ethiopian date
SELECT *
FROM your_table
WHERE to_ethiopian_date(created_at::timestamp) = '2016-08-15';
```

## Tips

1. **Date Format**: Always use `YYYY-MM-DD` format for Ethiopian dates
2. **Time Component**: `to_ethiopian_date()` discards time, only converts date
3. **Time Preservation**: Use `to_ethiopian_datetime()` if you need to preserve time
4. **NULL Handling**: Functions return NULL if input is NULL
5. **Both Naming Styles**: You can use either `to_ethiopian_date()` or `pg_ethiopian_to_date()`

## Troubleshooting

### Extension Not Found

```sql
-- Check if extension is installed
SELECT * FROM pg_extension WHERE extname = 'pg_ethiopian_calendar';

-- If not found, create it
CREATE EXTENSION pg_ethiopian_calendar;
```

### Invalid Date Format

```sql
-- Ethiopian dates must be in YYYY-MM-DD format
-- This will work:
SELECT from_ethiopian_date('2016-04-23');

-- This will fail:
SELECT from_ethiopian_date('23-04-2016');  -- Wrong format
```

### Check All Functions

```sql
-- List all available functions
SELECT 
    proname AS function_name,
    pg_get_function_arguments(oid) AS arguments
FROM pg_proc 
WHERE proname LIKE '%ethiopian%'
ORDER BY proname;
```

