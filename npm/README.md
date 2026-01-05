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

## Generated Columns (Timestamp)

Use `to_ethiopian_timestamp()` for DateTime/Timestamp columns:

```sql
CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP DEFAULT NOW(),
  created_at_ethiopian TIMESTAMP GENERATED ALWAYS AS 
    (to_ethiopian_timestamp(created_at)) STORED
);
```

For text format, use `to_ethiopian_date()`:

```sql
CREATE TABLE events (
  id SERIAL PRIMARY KEY,
  event_date TIMESTAMP NOT NULL,
  event_date_ethiopian VARCHAR(10) GENERATED ALWAYS AS 
    (to_ethiopian_date(event_date)) STORED
);
```

## With Prisma

### Schema

```prisma
model Order {
  id                 Int       @id @default(autoincrement())
  createdAt          DateTime  @default(now()) @map("created_at")
  createdAtEthiopian DateTime? @map("created_at_ethiopian")  // Generated column

  @@map("orders")
}
```

### ⚠️ Important: Migration Workflow

Prisma doesn't natively support `GENERATED ALWAYS AS` columns. You must create migrations manually:

```bash
# ❌ DON'T do this - Prisma will generate wrong SQL
npx prisma migrate dev

# ✅ DO this instead - create empty migration, then edit
npx prisma migrate dev --create-only --name add_orders_table
```

Then manually edit `migration.sql`:

```sql
CREATE TABLE "orders" (
    "id" SERIAL PRIMARY KEY,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at_ethiopian" TIMESTAMP(3) GENERATED ALWAYS AS 
        (to_ethiopian_timestamp(created_at)) STORED
);
```

Finally apply:

```bash
npx prisma migrate deploy
```

### Usage

```typescript
const order = await prisma.order.create({
  data: { name: 'Test' }
});
console.log(order.createdAtEthiopian); // auto-populated DateTime!
```

## With Drizzle

Drizzle has native support for generated columns:

```typescript
import { sql } from 'drizzle-orm';

export const orders = pgTable('orders', {
  id: serial('id').primaryKey(),
  createdAt: timestamp('created_at').defaultNow(),
  createdAtEthiopian: timestamp('created_at_ethiopian')
    .generatedAlwaysAs(sql`to_ethiopian_timestamp(created_at)`),
});
```

## With TypeORM

Use raw SQL in migrations:

```typescript
export class AddEthiopianCalendar1234567890 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    // First, run the ethiopian calendar SQL from the package
    await queryRunner.query(`/* ethiopian calendar functions */`);
    
    // Then create table with generated column
    await queryRunner.query(`
      CREATE TABLE "orders" (
        "id" SERIAL PRIMARY KEY,
        "created_at" TIMESTAMP DEFAULT NOW(),
        "created_at_ethiopian" TIMESTAMP GENERATED ALWAYS AS 
          (to_ethiopian_timestamp(created_at)) STORED
      )
    `);
  }
}
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

## Examples

Complete working examples are available for each ORM:

| Example | Description | Port |
|---------|-------------|------|
| [Prisma](https://github.com/HuluWZ/pg-ethiopian-calendar/tree/main/examples/prisma) | E-commerce demo | 3001 |
| [Drizzle](https://github.com/HuluWZ/pg-ethiopian-calendar/tree/main/examples/drizzle) | Event management | 3002 |
| [TypeORM](https://github.com/HuluWZ/pg-ethiopian-calendar/tree/main/examples/typeorm) | Blog platform | 3003 |

```bash
# Clone and run an example
git clone https://github.com/HuluWZ/pg-ethiopian-calendar.git
cd pg-ethiopian-calendar/examples/drizzle
npm install
cp env.example .env  # Configure DATABASE_URL
npm run dev
```

📖 [All Examples](https://github.com/HuluWZ/pg-ethiopian-calendar/tree/main/examples)

## Links

- [GitHub](https://github.com/HuluWZ/pg-ethiopian-calendar)
- [Documentation](https://github.com/HuluWZ/pg-ethiopian-calendar#readme)

## License

PostgreSQL License
