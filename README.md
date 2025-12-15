# pg_ethiopian_calendar

[![PGXN version](https://badge.fury.io/pg/pg_ethiopian_calendar.svg)](https://pgxn.org/dist/pg_ethiopian_calendar/)
[![Version](https://img.shields.io/badge/version-1.1.0-green.svg)](https://pgxn.org/dist/pg_ethiopian_calendar/)
[![PostgreSQL 11+](https://img.shields.io/badge/PostgreSQL-11+-blue.svg)](https://www.postgresql.org/)
[![License: PostgreSQL](https://img.shields.io/badge/License-PostgreSQL-blue.svg)](LICENSE)

A PostgreSQL extension for converting between Gregorian and Ethiopian calendar dates.

## Description

The Ethiopian calendar (Ge'ez calendar) is a solar calendar with 13 months used in Ethiopia and Eritrea. This extension provides functions to convert dates between Gregorian and Ethiopian calendars using academically verified algorithms from "Calendrical Calculations" by Dershowitz & Reingold.

**Key Features:**

- Bidirectional conversion (Gregorian ↔ Ethiopian)
- IMMUTABLE functions for use in indexes and generated columns
- Time-preserving conversions
- NULL-safe operations

## Installation

### From PGXN

```bash
pgxn install pg_ethiopian_calendar
```

### From Source

```bash
git clone https://github.com/HuluWZ/pg-ethiopian-calendar.git
cd pg-ethiopian-calendar
make
sudo make install
```

### Create Extension

```sql
CREATE EXTENSION pg_ethiopian_calendar;
```

## Quick Start

```sql
-- Convert Gregorian to Ethiopian
SELECT to_ethiopian_date('2024-01-01'::timestamp);
-- Returns: '2016-04-23'

-- Convert Ethiopian to Gregorian  
SELECT from_ethiopian_date('2016-04-23');
-- Returns: '2024-01-01 00:00:00'

-- Get current Ethiopian date
SELECT current_ethiopian_date();
-- Returns: Current date in Ethiopian calendar
```

## Functions

### to_ethiopian_date(timestamp) → text

Converts a Gregorian timestamp to Ethiopian date string.

```sql
SELECT to_ethiopian_date('2024-01-01'::timestamp);
-- '2016-04-23'
```

### from_ethiopian_date(text) → timestamp

Converts an Ethiopian date string to Gregorian timestamp.

```sql
SELECT from_ethiopian_date('2016-04-23');
-- '2024-01-01 00:00:00'
```

### to_ethiopian_timestamp(timestamp) → timestamp

Converts Gregorian timestamp to Ethiopian timestamp (preserves time). Ideal for generated columns.

```sql
SELECT to_ethiopian_timestamp('2024-01-01 14:30:00'::timestamp);
```

### to_ethiopian_datetime(timestamp) → timestamptz

Converts Gregorian timestamp to Ethiopian timestamp with time zone.

```sql
SELECT to_ethiopian_datetime('2024-01-01 14:30:00'::timestamp);
```

### current_ethiopian_date() → text

Returns current date in Ethiopian calendar. (STABLE, not IMMUTABLE)

```sql
SELECT current_ethiopian_date();
```

## Function Aliases

All functions have `pg_` prefixed aliases following PostgreSQL naming conventions:

| Function | Alias |
|----------|-------|
| `to_ethiopian_date()` | `pg_ethiopian_to_date()` |
| `from_ethiopian_date()` | `pg_ethiopian_from_date()` |
| `to_ethiopian_timestamp()` | `pg_ethiopian_to_timestamp()` |
| `to_ethiopian_datetime()` | `pg_ethiopian_to_datetime()` |

## Usage Examples

### Generated Columns

```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT NOW(),
    created_at_ethiopian TIMESTAMP GENERATED ALWAYS AS 
        (to_ethiopian_timestamp(created_at)) STORED
);

INSERT INTO orders DEFAULT VALUES;
SELECT * FROM orders;
```

### Default Values

```sql
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    event_date TEXT DEFAULT current_ethiopian_date()
);
```

### Indexing

```sql
CREATE INDEX idx_orders_ethiopian 
ON orders (to_ethiopian_date(created_at));
```

## Ethiopian Calendar Overview

| Property | Value |
|----------|-------|
| Months | 13 (12 × 30 days + 1 × 5-6 days) |
| Leap Year | Every 4 years (year % 4 == 3) |
| New Year | September 11-12 (Gregorian) |
| Year Offset | ~7-8 years behind Gregorian |

**Month Names:** Meskerem, Tikimt, Hidar, Tahsas, Tir, Yekatit, Megabit, Miazia, Ginbot, Sene, Hamle, Nehase, Pagumē

## Compatibility

- PostgreSQL 11, 12, 13, 14, 15, 16, 17

## Testing

```bash
# Using Docker
make docker-test

# Manual
psql -d mydb -f test/tests/ethiopian_calendar_tests.sql
```

## Author

**Hulunlante Worku** — [hulunlante.w@gmail.com](mailto:hulunlante.w@gmail.com)

## License

Released under the [PostgreSQL License](LICENSE).

## Links

- **PGXN:** <https://pgxn.org/dist/pg_ethiopian_calendar/>
- **GitHub:** <https://github.com/HuluWZ/pg-ethiopian-calendar>
- **Issues:** <https://github.com/HuluWZ/pg-ethiopian-calendar/issues>

## References

- Dershowitz, N. & Reingold, E.M. (2008). *Calendrical Calculations* (3rd ed.). Cambridge University Press.
