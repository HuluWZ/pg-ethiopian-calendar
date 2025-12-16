# pg_ethiopian_calendar

PostgreSQL extension for **Ethiopian (Ge'ez) calendar** date conversions.

[![GitHub](https://img.shields.io/badge/GitHub-HuluWZ%2Fpg--ethiopian--calendar-blue)](https://github.com/HuluWZ/pg-ethiopian-calendar)
[![PGXN](https://img.shields.io/badge/PGXN-pg__ethiopian__calendar-blue)](https://pgxn.org/dist/pg_ethiopian_calendar/)

## Quick Start

```bash
docker run -d \
  --name ethiopian-calendar-db \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  huluwz/pg-ethiopian-calendar:latest
```

Connect and use immediately:

```bash
psql -h localhost -U postgres -c "SELECT to_ethiopian_date(NOW());"
```

## Supported Tags

| Tag | PostgreSQL Version |
|-----|-------------------|
| `1.1.0-pg17`, `latest` | PostgreSQL 17 |
| `1.1.0-pg16` | PostgreSQL 16 |
| `1.1.0-pg15` | PostgreSQL 15 |
| `1.1.0-pg14` | PostgreSQL 14 |

## Features

- **`to_ethiopian_date(date)`** - Convert Gregorian date to Ethiopian calendar
- **`to_gregorian_date(text)`** - Convert Ethiopian date back to Gregorian
- **`current_ethiopian_date()`** - Get today's date in Ethiopian calendar
- **`to_ethiopian_timestamp(timestamp)`** - Convert timestamps (preserves time)
- **`ethiopian_date_parts(date)`** - Get year, month, day as record

## Example Usage

```sql
-- The extension is auto-loaded, just use it!

-- Convert dates
SELECT to_ethiopian_date('2024-12-16');  -- Returns: 2017-04-06

-- Get current Ethiopian date
SELECT current_ethiopian_date();

-- Use in tables with generated columns
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT NOW(),
    created_at_ethiopian TEXT GENERATED ALWAYS AS (to_ethiopian_date(created_at::date)) STORED
);
```

## Ethiopian Calendar

The Ethiopian calendar is:
- **7-8 years behind** the Gregorian calendar
- Has **13 months** (12 months of 30 days + 1 month of 5-6 days)
- New Year falls on **September 11** (or 12 in leap years)

## Source Code

Full documentation and source code available at:
- **GitHub:** https://github.com/HuluWZ/pg-ethiopian-calendar
- **PGXN:** https://pgxn.org/dist/pg_ethiopian_calendar/

## License

PostgreSQL License

