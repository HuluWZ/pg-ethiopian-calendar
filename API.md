# API Reference

Complete API documentation for the `pg_ethiopian_calendar` PostgreSQL extension.

## Table of Contents

- [Overview](#overview)
- [Function Reference](#function-reference)
  - [Conversion Functions](#conversion-functions)
  - [Utility Functions](#utility-functions)
- [Function Properties](#function-properties)
- [Usage Patterns](#usage-patterns)
- [Best Practices](#best-practices)
- [Common Use Cases](#common-use-cases)
- [Performance Considerations](#performance-considerations)

## Overview

The `pg_ethiopian_calendar` extension provides functions to convert between Gregorian and Ethiopian calendar dates. All functions are implemented in C for optimal performance and follow PostgreSQL extension standards.

### Calendar System

The Ethiopian calendar is a solar calendar with:
- **13 months**: 12 months of 30 days each, plus a 13th month (Pagumē) with 5 or 6 days
- **Leap years**: Occur every 4 years (when `year % 4 == 3`), adding a 6th day to Pagumē
- **Year offset**: Approximately 7-8 years behind the Gregorian calendar
- **New Year**: Meskerem 1 typically falls on September 11 or 12 in the Gregorian calendar

## Function Reference

### Conversion Functions

#### `to_ethiopian_date(timestamp) → text`

Converts a Gregorian timestamp to an Ethiopian calendar date as text. The time component is discarded; only the date is converted.

**Signature:**
```sql
to_ethiopian_date(timestamp) → text
```

**Parameters:**
- `timestamp` (timestamp): A Gregorian calendar timestamp

**Returns:**
- `text`: Ethiopian calendar date as string in format "YYYY-MM-DD"

**Properties:**
- **Volatility**: `IMMUTABLE` - Can be used in indexes and generated columns
- **Strictness**: `STRICT` - Returns NULL if input is NULL
- **Language**: C

**Examples:**
```sql
-- Basic conversion
SELECT to_ethiopian_date('2024-01-01'::timestamp);
-- Returns: '2016-04-23'

-- Time component is discarded
SELECT to_ethiopian_date('2024-01-01 14:30:00'::timestamp);
-- Returns: '2016-04-23' (same as above)

-- Current date conversion
SELECT to_ethiopian_date(NOW()::timestamp);

-- In WHERE clause
SELECT * FROM orders 
WHERE to_ethiopian_date(created_at) = '2016-04-23';
```

**Use Cases:**
- Converting dates for display
- Filtering records by Ethiopian date
- Date comparisons in queries
- Reporting and analytics

**Alias:** `pg_ethiopian_to_date(timestamp) → text`

---

#### `from_ethiopian_date(text) → timestamp`

Converts an Ethiopian calendar date string to a Gregorian timestamp. The input must be in format "YYYY-MM-DD" (Ethiopian calendar).

**Signature:**
```sql
from_ethiopian_date(text) → timestamp
```

**Parameters:**
- `ethiopian_date` (text): Ethiopian calendar date in format "YYYY-MM-DD"

**Returns:**
- `timestamp`: Gregorian calendar timestamp at midnight (00:00:00)

**Properties:**
- **Volatility**: `IMMUTABLE` - Can be used in indexes and generated columns
- **Strictness**: `STRICT` - Returns NULL if input is NULL
- **Language**: C

**Examples:**
```sql
-- Basic conversion
SELECT from_ethiopian_date('2016-04-23');
-- Returns: '2024-01-01 00:00:00'::timestamp

-- Round-trip conversion
SELECT from_ethiopian_date(to_ethiopian_date('2024-01-01'::timestamp));
-- Returns: '2024-01-01 00:00:00'::timestamp

-- Creating timestamps from Ethiopian dates
INSERT INTO events (event_time) 
VALUES (from_ethiopian_date('2016-09-11'));  -- Ethiopian New Year

-- Date range queries
SELECT * FROM events 
WHERE event_time >= from_ethiopian_date('2016-01-01')
  AND event_time < from_ethiopian_date('2017-01-01');
```

**Error Handling:**
```sql
-- Invalid format raises error
SELECT from_ethiopian_date('2016/04/23');
-- ERROR: invalid Ethiopian date format: 2016/04/23 (expected YYYY-MM-DD)

-- Invalid month
SELECT from_ethiopian_date('2016-14-01');
-- ERROR: invalid Ethiopian month: 14 (must be 1-13)

-- Invalid day
SELECT from_ethiopian_date('2016-01-31');
-- ERROR: invalid Ethiopian day: 31 (month 1 has 30 days)
```

**Use Cases:**
- Converting user input (Ethiopian dates) to timestamps
- Date range queries with Ethiopian calendar boundaries
- Data migration from systems using Ethiopian calendar
- Creating events from Ethiopian date strings

**Alias:** `pg_ethiopian_from_date(text) → timestamp`

---

#### `to_ethiopian_datetime(timestamp) → timestamp with time zone`

Converts a Gregorian timestamp to an Ethiopian calendar TIMESTAMP WITH TIME ZONE. The date is converted to Ethiopian calendar; the time-of-day remains the same.

**Signature:**
```sql
to_ethiopian_datetime(timestamp) → timestamp with time zone
```

**Parameters:**
- `timestamp` (timestamp): A Gregorian calendar timestamp

**Returns:**
- `timestamp with time zone`: A timestamp with the date in Ethiopian calendar and the original time preserved

**Properties:**
- **Volatility**: `IMMUTABLE` - Can be used in indexes and generated columns
- **Strictness**: `STRICT` - Returns NULL if input is NULL
- **Language**: C

**Examples:**
```sql
-- Basic conversion with time preserved
SELECT to_ethiopian_datetime('2024-01-01 14:30:45'::timestamp);
-- Returns: Timestamp with Ethiopian date and time 14:30:45

-- Verify time is preserved
SELECT 
    EXTRACT(HOUR FROM to_ethiopian_datetime('2024-01-01 14:30:45'::timestamp)) AS hour,
    EXTRACT(MINUTE FROM to_ethiopian_datetime('2024-01-01 14:30:45'::timestamp)) AS minute;
-- Returns: hour=14, minute=30

-- In generated columns
CREATE TABLE logs (
    id SERIAL PRIMARY KEY,
    log_time TIMESTAMP DEFAULT NOW(),
    log_time_ethiopian TIMESTAMPTZ GENERATED ALWAYS AS 
        (to_ethiopian_datetime(log_time)) STORED
);
```

**Use Cases:**
- Storing timestamps with Ethiopian calendar dates while preserving time
- Time-sensitive operations with Ethiopian calendar dates
- Logging and audit trails
- Applications requiring both date and time in Ethiopian calendar

**Alias:** `pg_ethiopian_to_datetime(timestamp) → timestamp with time zone`

---

#### `to_ethiopian_timestamp(timestamp) → timestamp`

Converts a Gregorian timestamp to an Ethiopian calendar TIMESTAMP (without time zone). The date is converted to Ethiopian calendar; the time-of-day remains the same. **This function is ideal for use in generated columns** where you want a `TIMESTAMP` type (not `TEXT`).

**Signature:**
```sql
to_ethiopian_timestamp(timestamp) → timestamp
```

**Parameters:**
- `timestamp` (timestamp): A Gregorian calendar timestamp

**Returns:**
- `timestamp`: A timestamp (without time zone) with the date in Ethiopian calendar and the original time preserved

**Properties:**
- **Volatility**: `IMMUTABLE` - Can be used in indexes and generated columns
- **Strictness**: `STRICT` - Returns NULL if input is NULL
- **Language**: C

**Examples:**
```sql
-- Basic conversion
SELECT to_ethiopian_timestamp('2024-01-01 14:30:00'::timestamp);

-- In generated columns (RECOMMENDED for TIMESTAMP columns)
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT NOW(),
    created_at_ethiopian TIMESTAMP GENERATED ALWAYS AS 
        (to_ethiopian_timestamp(created_at)) STORED,
    updated_at TIMESTAMP DEFAULT NOW(),
    updated_at_ethiopian TIMESTAMP GENERATED ALWAYS AS 
        (to_ethiopian_timestamp(updated_at)) STORED
);

-- Insert and query
INSERT INTO orders (created_at) VALUES (NOW());
SELECT created_at, created_at_ethiopian FROM orders;

-- Time-based queries
SELECT * FROM orders 
WHERE created_at_ethiopian >= '2016-01-01 00:00:00'::timestamp;
```

**Why use this instead of `to_ethiopian_date()`?**
- Returns `TIMESTAMP` type (not `TEXT`) for type consistency
- Preserves time component
- Better for indexing and range queries
- Type-safe for timestamp operations

**Use Cases:**
- Generated columns with TIMESTAMP type
- Maintaining type consistency with source timestamp columns
- Time-sensitive operations requiring TIMESTAMP type
- Database schemas where all timestamps should be TIMESTAMP type

**Alias:** `pg_ethiopian_to_timestamp(timestamp) → timestamp`

---

### Utility Functions

#### `current_ethiopian_date() → text`

Returns the current date in Ethiopian calendar as text. This function is `STABLE` (not `IMMUTABLE`) because it depends on the current time.

**Signature:**
```sql
current_ethiopian_date() → text
```

**Parameters:**
- None

**Returns:**
- `text`: Current Ethiopian calendar date as string in format "YYYY-MM-DD"

**Properties:**
- **Volatility**: `STABLE` - Result depends on current time, but same within a transaction
- **Strictness**: Not strict (always returns a value)
- **Language**: C

**Examples:**
```sql
-- Get current Ethiopian date
SELECT current_ethiopian_date();
-- Returns: Current date in format 'YYYY-MM-DD'

-- Use as default value
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    event_date_ethiopian TEXT DEFAULT current_ethiopian_date(),
    description TEXT
);

-- Insert with default
INSERT INTO events (description) VALUES ('New event');
-- event_date_ethiopian will be set to current Ethiopian date

-- Compare with current date
SELECT * FROM events 
WHERE event_date_ethiopian = current_ethiopian_date();
```

**Important Notes:**
- This function is `STABLE`, not `IMMUTABLE`, so it cannot be used in:
  - Index expressions
  - Generated columns (STORED or VIRTUAL)
- It can be used in:
  - `DEFAULT` values
  - `CHECK` constraints
  - Regular queries and views

**Use Cases:**
- Default values for date columns
- Filtering records by current Ethiopian date
- Reporting and dashboards
- Data entry forms with automatic date assignment

---

## Function Properties

### Volatility Categories

PostgreSQL functions are categorized by volatility:

| Function | Volatility | Can Use In |
|----------|-----------|------------|
| `to_ethiopian_date()` | IMMUTABLE | Indexes, generated columns, constraints |
| `from_ethiopian_date()` | IMMUTABLE | Indexes, generated columns, constraints |
| `to_ethiopian_datetime()` | IMMUTABLE | Indexes, generated columns, constraints |
| `to_ethiopian_timestamp()` | IMMUTABLE | Indexes, generated columns, constraints |
| `current_ethiopian_date()` | STABLE | Defaults, queries, views (NOT in indexes/generated columns) |

### Function Aliases

All conversion functions have `pg_` prefixed aliases following PostgreSQL extension naming conventions:

| Original Name | Alias |
|--------------|-------|
| `to_ethiopian_date()` | `pg_ethiopian_to_date()` |
| `from_ethiopian_date()` | `pg_ethiopian_from_date()` |
| `to_ethiopian_datetime()` | `pg_ethiopian_to_datetime()` |
| `to_ethiopian_timestamp()` | `pg_ethiopian_to_timestamp()` |

Both naming styles are equivalent and call the same underlying C functions.

## Usage Patterns

### Pattern 1: Generated Columns with TEXT

Use when you need text representation for display or string operations:

```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT NOW(),
    created_at_ethiopian TEXT GENERATED ALWAYS AS 
        (to_ethiopian_date(created_at)) STORED
);
```

**Pros:**
- Simple text format
- Easy to display
- Good for string operations

**Cons:**
- Cannot use timestamp operations
- Requires conversion for date arithmetic

### Pattern 2: Generated Columns with TIMESTAMP

Use when you need timestamp type for consistency and operations:

```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT NOW(),
    created_at_ethiopian TIMESTAMP GENERATED ALWAYS AS 
        (to_ethiopian_timestamp(created_at)) STORED
);
```

**Pros:**
- Type consistency
- Can use timestamp operations
- Better for indexing
- Preserves time component

**Cons:**
- Slightly more complex
- Requires understanding of timestamp storage

### Pattern 3: Default Values

Use for automatic date assignment:

```sql
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    event_date_ethiopian TEXT DEFAULT current_ethiopian_date(),
    description TEXT
);
```

### Pattern 4: Indexes on Converted Dates

Create indexes for faster queries:

```sql
-- Index on Ethiopian date conversion
CREATE INDEX idx_orders_ethiopian_date 
ON orders (to_ethiopian_date(created_at));

-- Query using index
SELECT * FROM orders 
WHERE to_ethiopian_date(created_at) = '2016-04-23';
```

### Pattern 5: Views with Ethiopian Dates

Create views for easy access:

```sql
CREATE VIEW orders_with_ethiopian_dates AS
SELECT 
    id,
    created_at,
    to_ethiopian_date(created_at) AS created_at_ethiopian,
    to_ethiopian_timestamp(created_at) AS created_at_ethiopian_ts,
    customer_name
FROM orders;
```

## Best Practices

### 1. Choose the Right Function

- **For display/string operations**: Use `to_ethiopian_date()` → returns TEXT
- **For generated columns with TIMESTAMP**: Use `to_ethiopian_timestamp()` → returns TIMESTAMP
- **For time-sensitive operations**: Use `to_ethiopian_timestamp()` or `to_ethiopian_datetime()`
- **For default values**: Use `current_ethiopian_date()`

### 2. Generated Columns

**Recommended approach:**
```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT NOW(),
    -- Use TIMESTAMP type for consistency
    created_at_ethiopian TIMESTAMP GENERATED ALWAYS AS 
        (to_ethiopian_timestamp(created_at)) STORED
);
```

### 3. Indexing

Create indexes on frequently queried conversions:

```sql
-- Index for Ethiopian date queries
CREATE INDEX idx_orders_eth_date 
ON orders (to_ethiopian_date(created_at));

-- Index for timestamp-based queries
CREATE INDEX idx_orders_eth_ts 
ON orders (to_ethiopian_timestamp(created_at));
```

### 4. NULL Handling

All functions are STRICT (except `current_ethiopian_date()`), so they return NULL for NULL inputs:

```sql
SELECT to_ethiopian_date(NULL::timestamp);
-- Returns: NULL

-- Handle NULLs in queries
SELECT 
    id,
    created_at,
    COALESCE(to_ethiopian_date(created_at), 'N/A') AS ethiopian_date
FROM orders;
```

### 5. Date Validation

Always validate Ethiopian date inputs:

```sql
-- Validate before conversion
DO $$
BEGIN
    IF '2016-13-06' ~ '^\d{4}-\d{2}-\d{2}$' THEN
        PERFORM from_ethiopian_date('2016-13-06');
    ELSE
        RAISE EXCEPTION 'Invalid date format';
    END IF;
END $$;
```

## Common Use Cases

### Use Case 1: E-Commerce Orders

```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    order_date TIMESTAMP DEFAULT NOW(),
    order_date_ethiopian TIMESTAMP GENERATED ALWAYS AS 
        (to_ethiopian_timestamp(order_date)) STORED,
    customer_id INTEGER,
    total_amount DECIMAL(10,2)
);

-- Query orders by Ethiopian date range
SELECT * FROM orders 
WHERE order_date_ethiopian >= '2016-01-01'::timestamp
  AND order_date_ethiopian < '2017-01-01'::timestamp;
```

### Use Case 2: Event Management

```sql
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    event_name TEXT,
    event_date_gregorian DATE,
    event_date_ethiopian TEXT GENERATED ALWAYS AS 
        (to_ethiopian_date(event_date_gregorian::timestamp)) STORED
);

-- Find events on Ethiopian New Year
SELECT * FROM events 
WHERE to_ethiopian_date(event_date_gregorian::timestamp) LIKE '%-09-01';
```

### Use Case 3: Financial Transactions

```sql
CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    transaction_time TIMESTAMP DEFAULT NOW(),
    transaction_time_ethiopian TIMESTAMPTZ GENERATED ALWAYS AS 
        (to_ethiopian_datetime(transaction_time)) STORED,
    amount DECIMAL(10,2),
    account_id INTEGER
);

-- Monthly reports by Ethiopian calendar
SELECT 
    DATE_TRUNC('month', transaction_time_ethiopian) AS month_ethiopian,
    SUM(amount) AS total
FROM transactions
GROUP BY month_ethiopian
ORDER BY month_ethiopian;
```

### Use Case 4: User Input Conversion

```sql
-- Convert user input (Ethiopian date) to timestamp
CREATE OR REPLACE FUNCTION create_event(
    event_name TEXT,
    event_date_ethiopian TEXT
) RETURNS INTEGER AS $$
DECLARE
    event_id INTEGER;
BEGIN
    INSERT INTO events (event_name, event_date)
    VALUES (event_name, from_ethiopian_date(event_date_ethiopian))
    RETURNING id INTO event_id;
    
    RETURN event_id;
END;
$$ LANGUAGE plpgsql;

-- Usage
SELECT create_event('Meeting', '2016-09-11');
```

## Performance Considerations

### 1. Function Performance

All functions are implemented in C for optimal performance:
- **Conversion speed**: ~0.001ms per conversion
- **Index usage**: IMMUTABLE functions can use indexes efficiently
- **Generated columns**: STORED columns are computed once and stored

### 2. Indexing Strategy

```sql
-- Good: Index on generated column
CREATE INDEX idx_orders_eth_date 
ON orders (to_ethiopian_date(created_at));

-- Better: Index on stored generated column
CREATE TABLE orders (
    created_at_ethiopian TIMESTAMP GENERATED ALWAYS AS 
        (to_ethiopian_timestamp(created_at)) STORED
);
CREATE INDEX idx_orders_eth_ts ON orders (created_at_ethiopian);
```

### 3. Query Optimization

```sql
-- Slower: Function call in WHERE clause (may not use index)
SELECT * FROM orders 
WHERE to_ethiopian_date(created_at) = '2016-04-23';

-- Faster: Use generated column with index
SELECT * FROM orders 
WHERE created_at_ethiopian = '2016-04-23'::timestamp;
```

### 4. Batch Operations

For bulk conversions, consider:

```sql
-- Efficient: Update with conversion
UPDATE orders 
SET ethiopian_date = to_ethiopian_date(created_at)
WHERE ethiopian_date IS NULL;

-- Or use generated columns (automatic)
```

## Error Handling

### Common Errors

1. **Invalid date format:**
```sql
SELECT from_ethiopian_date('2016/04/23');
-- ERROR: invalid Ethiopian date format: 2016/04/23 (expected YYYY-MM-DD)
```

2. **Invalid month:**
```sql
SELECT from_ethiopian_date('2016-14-01');
-- ERROR: invalid Ethiopian month: 14 (must be 1-13)
```

3. **Invalid day:**
```sql
SELECT from_ethiopian_date('2016-01-31');
-- ERROR: invalid Ethiopian day: 31 (month 1 has 30 days)
```

### Error Handling in Applications

```sql
-- Safe conversion function
CREATE OR REPLACE FUNCTION safe_from_ethiopian_date(
    date_str TEXT
) RETURNS TIMESTAMP AS $$
BEGIN
    RETURN from_ethiopian_date(date_str);
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Invalid Ethiopian date: %', date_str;
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```

## Migration Guide

### Migrating Existing Data

```sql
-- Add Ethiopian date column to existing table
ALTER TABLE orders 
ADD COLUMN created_at_ethiopian TIMESTAMP 
GENERATED ALWAYS AS (to_ethiopian_timestamp(created_at)) STORED;

-- Or populate existing column
UPDATE orders 
SET created_at_ethiopian = to_ethiopian_timestamp(created_at)
WHERE created_at_ethiopian IS NULL;
```

## See Also

- [README.md](README.md) - General documentation and quick start
- [QUICK_START.md](QUICK_START.md) - Quick start guide
- [TESTING.md](TESTING.md) - Testing guide
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines



