# @huluwz/pg-ethiopian-calendar

Ethiopian calendar functions for PostgreSQL. Works on any PostgreSQL including managed services (Neon, Supabase, Railway, AWS RDS).

[![npm](https://img.shields.io/npm/v/@huluwz/pg-ethiopian-calendar)](https://www.npmjs.com/package/@huluwz/pg-ethiopian-calendar)
[![License](https://img.shields.io/badge/license-PostgreSQL-blue)](LICENSE)

## Install

```bash
npm install @huluwz/pg-ethiopian-calendar
```

## Quick Start

```bash
# Generate migration (auto-detects ORM)
npx ethiopian-calendar init

# Or specify ORM
npx ethiopian-calendar init prisma
npx ethiopian-calendar init drizzle
npx ethiopian-calendar init typeorm
```

Then run your ORM's migration command.

## SQL Functions

```sql
-- Current Ethiopian date (two ways)
SELECT to_ethiopian_date();                         -- '2018-04-23'
SELECT to_ethiopian_date(NOW());                    -- same

-- Specific date
SELECT to_ethiopian_date('2024-01-01'::timestamp);  -- '2016-04-23'

-- Ethiopian → Gregorian
SELECT from_ethiopian_date('2016-04-23');           -- '2024-01-01 00:00:00'

-- Current Ethiopian timestamp (with time)
SELECT to_ethiopian_timestamp();                    -- '2018-04-23 14:30:00'

-- Check version
SELECT ethiopian_calendar_version();                -- '1.1.0'
```

## Generated Columns

```sql
CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP DEFAULT NOW(),
  created_at_ethiopian TIMESTAMP GENERATED ALWAYS AS 
    (to_ethiopian_timestamp(created_at)) STORED
);
```

## With Prisma

```typescript
const order = await prisma.order.create({
  data: { name: 'Test' }
});
console.log(order.createdAtEthiopian); // auto-populated
```

## With Drizzle

```typescript
import { sql } from 'drizzle-orm';

export const orders = pgTable('orders', {
  id: serial('id').primaryKey(),
  createdAt: timestamp('created_at').defaultNow(),
  createdAtEthiopian: timestamp('created_at_ethiopian')
    .generatedAlwaysAs(sql`to_ethiopian_timestamp(created_at)`),
});
```

## API

```typescript
import { getSql, VERSION, detectOrm } from '@huluwz/pg-ethiopian-calendar';

getSql();        // Full SQL content
detectOrm();     // Auto-detect installed ORM
VERSION;         // '1.1.0'
```

## Supported ORMs

- Prisma
- Drizzle
- TypeORM
- Raw SQL

## Links

- [GitHub](https://github.com/HuluWZ/pg-ethiopian-calendar)
- [Documentation](https://github.com/HuluWZ/pg-ethiopian-calendar#readme)

## License

PostgreSQL License
