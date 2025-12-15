# Quick Reference

Quick reference guide for `pg_ethiopian_calendar` extension functions.

## Function Cheat Sheet

### Conversion Functions

| Function | Input | Output | Use Case |
|----------|-------|--------|----------|
| `to_ethiopian_date(ts)` | `timestamp` | `text` | Display, string operations |
| `from_ethiopian_date(str)` | `text` | `timestamp` | Convert user input |
| `to_ethiopian_datetime(ts)` | `timestamp` | `timestamptz` | With time zone |
| `to_ethiopian_timestamp(ts)` | `timestamp` | `timestamp` | Generated columns (TIMESTAMP) |
| `current_ethiopian_date()` | - | `text` | Default values |

### Aliases (pg_ prefixed)

| Original | Alias |
|----------|-------|
| `to_ethiopian_date()` | `pg_ethiopian_to_date()` |
| `from_ethiopian_date()` | `pg_ethiopian_from_date()` |
| `to_ethiopian_datetime()` | `pg_ethiopian_to_datetime()` |
| `to_ethiopian_timestamp()` | `pg_ethiopian_to_timestamp()` |

## Quick Examples

### Basic Conversions

```sql
-- Gregorian → Ethiopian (text)
SELECT to_ethiopian_date('2024-01-01'::timestamp);
-- '2016-04-23'

-- Ethiopian → Gregorian
SELECT from_ethiopian_date('2016-04-23');
-- '2024-01-01 00:00:00'::timestamp

-- Current date
SELECT current_ethiopian_date();
-- Current date in 'YYYY-MM-DD' format
```

### Generated Columns

```sql
-- TEXT type (for display)
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT NOW(),
    created_at_ethiopian TEXT GENERATED ALWAYS AS 
        (to_ethiopian_date(created_at)) STORED
);

-- TIMESTAMP type (recommended)
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT NOW(),
    created_at_ethiopian TIMESTAMP GENERATED ALWAYS AS 
        (to_ethiopian_timestamp(created_at)) STORED
);
```

### Default Values

```sql
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    event_date_ethiopian TEXT DEFAULT current_ethiopian_date()
);
```

### Queries

```sql
-- Filter by Ethiopian date
SELECT * FROM orders 
WHERE to_ethiopian_date(created_at) = '2016-04-23';

-- Date range
SELECT * FROM events 
WHERE event_time >= from_ethiopian_date('2016-01-01')
  AND event_time < from_ethiopian_date('2017-01-01');

-- Using generated column
SELECT * FROM orders 
WHERE created_at_ethiopian >= '2016-01-01'::timestamp;
```

## Function Properties

| Function | Volatility | Can Use In |
|----------|-----------|------------|
| `to_ethiopian_date()` | IMMUTABLE | Indexes, generated columns |
| `from_ethiopian_date()` | IMMUTABLE | Indexes, generated columns |
| `to_ethiopian_datetime()` | IMMUTABLE | Indexes, generated columns |
| `to_ethiopian_timestamp()` | IMMUTABLE | Indexes, generated columns |
| `current_ethiopian_date()` | STABLE | Defaults, queries (NOT in indexes) |

## When to Use Which Function

### Use `to_ethiopian_date()` when:
- ✅ You need text output for display
- ✅ String operations are required
- ✅ Simple date conversion (time not needed)

### Use `to_ethiopian_timestamp()` when:
- ✅ Generated columns with TIMESTAMP type
- ✅ Type consistency is important
- ✅ Time component needs to be preserved
- ✅ Indexing on Ethiopian dates

### Use `to_ethiopian_datetime()` when:
- ✅ Time zone awareness is needed
- ✅ TIMESTAMPTZ type is required

### Use `current_ethiopian_date()` when:
- ✅ Default values for date columns
- ✅ Current date in queries
- ❌ NOT in generated columns or indexes

## Common Patterns

### Pattern 1: Orders Table
```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    order_date TIMESTAMP DEFAULT NOW(),
    order_date_ethiopian TIMESTAMP GENERATED ALWAYS AS 
        (to_ethiopian_timestamp(order_date)) STORED
);
```

### Pattern 2: Events Table
```sql
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    event_date_ethiopian TEXT DEFAULT current_ethiopian_date(),
    description TEXT
);
```

### Pattern 3: Index on Conversion
```sql
CREATE INDEX idx_orders_eth_date 
ON orders (to_ethiopian_date(created_at));
```

## Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `invalid Ethiopian date format` | Wrong format | Use 'YYYY-MM-DD' |
| `invalid Ethiopian month` | Month > 13 | Use 1-13 |
| `invalid Ethiopian day` | Day too high | Check month limits (30 or 5-6) |

## See Also

- **[API.md](API.md)** - Complete API documentation
- **[README.md](README.md)** - Full documentation
- **[QUICK_START.md](QUICK_START.md)** - Getting started guide



