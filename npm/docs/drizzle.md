# Using Ethiopian Calendar with Drizzle ORM

## Quick Setup

```bash
# Install the package
npm install @huluwz/pg-ethiopian-calendar

# Generate migration
npx ethiopian-calendar init drizzle

# Apply migration
npx drizzle-kit migrate
```

## Manual Setup

If you prefer to set up manually:

### 1. Create Migration File

Copy the SQL from `node_modules/@huluwz/pg-ethiopian-calendar/sql/ethiopian_calendar.sql` to your Drizzle migrations folder (e.g., `drizzle/0001_ethiopian_calendar.sql`)

### 2. Apply Migration

```bash
npx drizzle-kit migrate
# or
npx drizzle-kit push
```

## Usage Examples

### Schema with Generated Columns

```typescript
import { pgTable, serial, timestamp, text } from 'drizzle-orm/pg-core'
import { sql } from 'drizzle-orm'

export const orders = pgTable('orders', {
  id: serial('id').primaryKey(),
  customerName: text('customer_name').notNull(),
  createdAt: timestamp('created_at').defaultNow(),
  
  // Generated column - Ethiopian date calculated automatically
  createdAtEthiopian: timestamp('created_at_ethiopian')
    .generatedAlwaysAs(sql`to_ethiopian_timestamp(created_at)`),
})
```

### Using in Queries

```typescript
import { db } from './db'
import { orders } from './schema'
import { sql } from 'drizzle-orm'

// Insert - Ethiopian date is auto-generated
const [order] = await db.insert(orders)
  .values({ customerName: 'Abebe Kebede' })
  .returning()

console.log(order.createdAtEthiopian) // Ethiopian timestamp!

// Get current Ethiopian date
const result = await db.execute(
  sql`SELECT current_ethiopian_date() as today`
)

// Convert a specific date
const converted = await db.execute(
  sql`SELECT to_ethiopian_date('2026-01-01'::timestamp) as ethiopian`
)

// Filter by Ethiopian date
const filtered = await db
  .select()
  .from(orders)
  .where(sql`to_ethiopian_date(created_at) = '2018-04-23'`)
```

### Creating Table with Raw SQL

If you prefer to create the table in a migration:

```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_name TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    created_at_ethiopian TIMESTAMP GENERATED ALWAYS AS 
        (to_ethiopian_timestamp(created_at)) STORED
);
```

### Functional Index

```typescript
import { index } from 'drizzle-orm/pg-core'
import { sql } from 'drizzle-orm'

// In your schema or migration
export const ordersEthiopianIdx = index('idx_orders_ethiopian')
  .on(sql`to_ethiopian_date(created_at)`)
```

Or in raw SQL:

```sql
CREATE INDEX idx_orders_ethiopian 
ON orders (to_ethiopian_date(created_at));
```

## Available Functions

| Function | Description |
|----------|-------------|
| `to_ethiopian_date(timestamp)` | Convert to Ethiopian date string (YYYY-MM-DD) |
| `from_ethiopian_date(text)` | Convert Ethiopian date to Gregorian timestamp |
| `to_ethiopian_timestamp(timestamp)` | Convert preserving time (for generated columns) |
| `current_ethiopian_date()` | Get current Ethiopian date |

## Using sql Template

All functions can be used with Drizzle's `sql` template:

```typescript
import { sql } from 'drizzle-orm'

// In select
const result = await db.select({
  id: orders.id,
  ethiopianDate: sql<string>`to_ethiopian_date(${orders.createdAt})`,
}).from(orders)

// In where
const filtered = await db.select()
  .from(orders)
  .where(sql`to_ethiopian_date(${orders.createdAt}) > '2018-01-01'`)
```

## Links

- [GitHub Repository](https://github.com/HuluWZ/pg-ethiopian-calendar)
- [NPM Package](https://www.npmjs.com/package/@huluwz/pg-ethiopian-calendar)
- [Drizzle ORM Docs](https://orm.drizzle.team/)

