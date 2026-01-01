# Using Ethiopian Calendar with Raw PostgreSQL

## Quick Setup

```bash
# Install the package
npm install @huluwz/pg-ethiopian-calendar

# Generate SQL file
npx ethiopian-calendar init raw

# Apply to database
psql -d your_database -f ethiopian_calendar.sql
```

## Manual Setup

### Option 1: Using psql

```bash
# Copy from node_modules
cp node_modules/@huluwz/pg-ethiopian-calendar/sql/ethiopian_calendar.sql .

# Apply to database
psql -h localhost -U postgres -d your_database -f ethiopian_calendar.sql
```

### Option 2: Using Node.js pg Client

```typescript
import { Pool } from 'pg';
import { getSql } from '@huluwz/pg-ethiopian-calendar';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

// Apply migration
await pool.query(getSql());
```

### Option 3: Using Any SQL Client

Copy the contents of `sql/ethiopian_calendar.sql` and execute in your preferred PostgreSQL client (pgAdmin, DBeaver, DataGrip, etc.)

## Usage Examples

### Basic Conversions

```sql
-- Convert Gregorian to Ethiopian
SELECT to_ethiopian_date('2026-01-01'::timestamp);
-- Returns: '2018-04-23'

-- Convert Ethiopian to Gregorian
SELECT from_ethiopian_date('2018-04-23');
-- Returns: '2026-01-01 00:00:00'

-- Get current Ethiopian date
SELECT current_ethiopian_date();
-- Returns: Current date in Ethiopian calendar

-- Convert with time preserved
SELECT to_ethiopian_timestamp('2026-01-01 14:30:00'::timestamp);
-- Returns: '2018-04-23 14:30:00'
```

### Generated Columns

```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_name TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    created_at_ethiopian TIMESTAMP GENERATED ALWAYS AS 
        (to_ethiopian_timestamp(created_at)) STORED,
    updated_at TIMESTAMP DEFAULT NOW(),
    updated_at_ethiopian TIMESTAMP GENERATED ALWAYS AS 
        (to_ethiopian_timestamp(updated_at)) STORED
);

-- Insert data
INSERT INTO orders (customer_name) VALUES ('Abebe Kebede');

-- Query - Ethiopian dates are automatically populated
SELECT * FROM orders;
```

### Default Values

```sql
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    event_name TEXT NOT NULL,
    event_date_ethiopian TEXT DEFAULT current_ethiopian_date()
);

INSERT INTO events (event_name) VALUES ('Meeting');
-- event_date_ethiopian is automatically set to current Ethiopian date
```

### Functional Indexes

```sql
-- Create index for fast queries by Ethiopian date
CREATE INDEX idx_orders_ethiopian 
ON orders (to_ethiopian_date(created_at));

-- This query will use the index
SELECT * FROM orders 
WHERE to_ethiopian_date(created_at) = '2018-04-23';
```

### Views

```sql
CREATE VIEW orders_with_ethiopian AS
SELECT 
    id,
    customer_name,
    created_at,
    to_ethiopian_date(created_at) as created_at_ethiopian,
    updated_at,
    to_ethiopian_date(updated_at) as updated_at_ethiopian
FROM orders;
```

### Using with Node.js pg Client

```typescript
import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

// Convert date
const { rows } = await pool.query(
  "SELECT to_ethiopian_date($1::timestamp) as ethiopian",
  ['2026-01-01']
);
console.log(rows[0].ethiopian); // '2018-04-23'

// Get current Ethiopian date
const { rows: todayRows } = await pool.query(
  "SELECT current_ethiopian_date() as today"
);
console.log(todayRows[0].today);

// Insert with Ethiopian date
await pool.query(`
  INSERT INTO orders (customer_name) VALUES ($1)
`, ['Abebe Kebede']);
// Ethiopian date columns are auto-populated by generated columns
```

## Available Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `to_ethiopian_date(timestamp)` | `text` | Convert to Ethiopian date string (YYYY-MM-DD) |
| `from_ethiopian_date(text)` | `timestamp` | Convert Ethiopian date to Gregorian timestamp |
| `to_ethiopian_timestamp(timestamp)` | `timestamp` | Convert preserving time (for generated columns) |
| `to_ethiopian_datetime(timestamp)` | `timestamptz` | Convert to timestamp with timezone |
| `current_ethiopian_date()` | `text` | Get current Ethiopian date |

### Aliases (pg_ prefix)

| Alias | Same as |
|-------|---------|
| `pg_ethiopian_to_date()` | `to_ethiopian_date()` |
| `pg_ethiopian_from_date()` | `from_ethiopian_date()` |
| `pg_ethiopian_to_timestamp()` | `to_ethiopian_timestamp()` |
| `pg_ethiopian_to_datetime()` | `to_ethiopian_datetime()` |

## Removing the Functions

If you need to remove the functions:

```sql
DROP FUNCTION IF EXISTS pg_ethiopian_to_datetime(timestamp);
DROP FUNCTION IF EXISTS pg_ethiopian_to_timestamp(timestamp);
DROP FUNCTION IF EXISTS pg_ethiopian_from_date(text);
DROP FUNCTION IF EXISTS pg_ethiopian_to_date(timestamp);
DROP FUNCTION IF EXISTS current_ethiopian_date();
DROP FUNCTION IF EXISTS to_ethiopian_datetime(timestamp);
DROP FUNCTION IF EXISTS to_ethiopian_timestamp(timestamp);
DROP FUNCTION IF EXISTS from_ethiopian_date(text);
DROP FUNCTION IF EXISTS to_ethiopian_date(timestamp);
DROP FUNCTION IF EXISTS _ethiopian_to_jdn(integer, integer, integer);
DROP FUNCTION IF EXISTS _jdn_to_ethiopian(integer);
DROP FUNCTION IF EXISTS _jdn_to_gregorian(integer);
DROP FUNCTION IF EXISTS _gregorian_to_jdn(integer, integer, integer);
```

## Links

- [GitHub Repository](https://github.com/HuluWZ/pg-ethiopian-calendar)
- [NPM Package](https://www.npmjs.com/package/@huluwz/pg-ethiopian-calendar)

