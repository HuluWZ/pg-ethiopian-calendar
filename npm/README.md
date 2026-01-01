# @huluwz/pg-ethiopian-calendar

[![npm version](https://badge.fury.io/js/@huluwz%2Fpg-ethiopian-calendar.svg)](https://www.npmjs.com/package/@huluwz/pg-ethiopian-calendar)
[![PostgreSQL 11+](https://img.shields.io/badge/PostgreSQL-11+-blue.svg)](https://www.postgresql.org/)
[![License: PostgreSQL](https://img.shields.io/badge/License-PostgreSQL-blue.svg)](LICENSE)

Ethiopian calendar functions for PostgreSQL. **Works with any ORM** - Prisma, Drizzle, TypeORM, Sequelize, Knex, and more.

**No Docker required. No C extension. Just SQL.**

## Features

- ✅ Works on **any PostgreSQL** (Neon, Supabase, Railway, AWS RDS, local)
- ✅ Compatible with **all ORMs** (Prisma, Drizzle, TypeORM, etc.)
- ✅ **Generated columns** support
- ✅ **Functional indexes** support
- ✅ **IMMUTABLE** functions for optimal performance
- ✅ One-command setup with CLI

## Quick Start

```bash
# Install
npm install @huluwz/pg-ethiopian-calendar

# Initialize (auto-detects your ORM)
npx ethiopian-calendar init

# Apply migration (example for Prisma)
npx prisma migrate dev
```

That's it! Ethiopian calendar functions are now available in your database.

## Usage

### SQL Functions

```sql
-- Convert Gregorian to Ethiopian
SELECT to_ethiopian_date('2026-01-01'::timestamp);
-- Returns: '2018-04-23'

-- Convert Ethiopian to Gregorian
SELECT from_ethiopian_date('2018-04-23');
-- Returns: '2026-01-01 00:00:00'

-- Get current Ethiopian date
SELECT current_ethiopian_date();
-- Returns: Today's date in Ethiopian calendar
```

### Generated Columns

```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT NOW(),
    created_at_ethiopian TIMESTAMP GENERATED ALWAYS AS 
        (to_ethiopian_timestamp(created_at)) STORED
);
```

### With Prisma

```typescript
// Ethiopian date is automatically populated!
const order = await prisma.order.create({
  data: { customerName: 'Abebe' }
})
console.log(order.createdAtEthiopian) // Ethiopian timestamp
```

### With Drizzle

```typescript
import { sql } from 'drizzle-orm'

export const orders = pgTable('orders', {
  id: serial('id').primaryKey(),
  createdAt: timestamp('created_at').defaultNow(),
  createdAtEthiopian: timestamp('created_at_ethiopian')
    .generatedAlwaysAs(sql`to_ethiopian_timestamp(created_at)`),
})
```

## CLI Commands

```bash
# Auto-detect ORM and generate migration
npx ethiopian-calendar init

# Specify ORM explicitly
npx ethiopian-calendar init prisma
npx ethiopian-calendar init drizzle
npx ethiopian-calendar init typeorm
npx ethiopian-calendar init sequelize
npx ethiopian-calendar init knex
npx ethiopian-calendar init raw
```

## Available Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `to_ethiopian_date(timestamp)` | `text` | Convert to Ethiopian date (YYYY-MM-DD) |
| `from_ethiopian_date(text)` | `timestamp` | Convert Ethiopian to Gregorian |
| `to_ethiopian_timestamp(timestamp)` | `timestamp` | Convert preserving time |
| `current_ethiopian_date()` | `text` | Current Ethiopian date |

## Programmatic Usage

```typescript
import { getSql, getSqlPath } from '@huluwz/pg-ethiopian-calendar'

// Get SQL content
const sql = getSql()

// Get path to SQL file
const path = getSqlPath()
```

## Documentation

- [Prisma Guide](./docs/prisma.md)
- [Drizzle Guide](./docs/drizzle.md)
- [TypeORM Guide](./docs/typeorm.md)
- [Raw SQL Guide](./docs/raw.md)

## Ethiopian Calendar

The Ethiopian calendar (Ge'ez calendar) is a solar calendar with:
- **13 months**: 12 months of 30 days + 1 month of 5-6 days
- **7-8 years behind** the Gregorian calendar
- **New Year** on September 11 (or 12 in leap years)

## Links

- [GitHub Repository](https://github.com/HuluWZ/pg-ethiopian-calendar)
- [C Extension (PGXN)](https://pgxn.org/dist/pg_ethiopian_calendar/)
- [Docker Image](https://hub.docker.com/r/huluwz/pg-ethiopian-calendar)

## Author

**Hulunlante Worku** — [hulunlante.w@gmail.com](mailto:hulunlante.w@gmail.com)

## License

[PostgreSQL License](LICENSE)

