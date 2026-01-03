# Using Ethiopian Calendar with TypeORM

## Quick Setup

```bash
# Install the package
npm install @huluwz/pg-ethiopian-calendar

# Generate migration
npx ethiopian-calendar init typeorm

# Apply migration
npx typeorm migration:run -d src/data-source.ts
```

## Manual Setup

### 1. Create Migration

```bash
npx typeorm migration:create src/migrations/EthiopianCalendar
```

### 2. Add SQL to Migration

```typescript
import { MigrationInterface, QueryRunner } from "typeorm";
import { getSql } from "@huluwz/pg-ethiopian-calendar";

export class EthiopianCalendar1704067200000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(getSql());
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
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
    `);
  }
}
```

### 3. Run Migration

```bash
npx typeorm migration:run -d src/data-source.ts
```

## Usage Examples

### Entity with Generated Column

First, create the table with a generated column via migration:

```typescript
// In a migration
public async up(queryRunner: QueryRunner): Promise<void> {
  await queryRunner.query(`
    CREATE TABLE orders (
      id SERIAL PRIMARY KEY,
      customer_name VARCHAR(255) NOT NULL,
      created_at TIMESTAMP DEFAULT NOW(),
      created_at_ethiopian TIMESTAMP GENERATED ALWAYS AS 
        (to_ethiopian_timestamp(created_at)) STORED
    );
  `);
}
```

Then define your entity:

```typescript
import { Entity, PrimaryGeneratedColumn, Column } from "typeorm";

@Entity("orders")
export class Order {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ name: "customer_name" })
  customerName: string;

  @Column({ name: "created_at", default: () => "NOW()" })
  createdAt: Date;

  // Read-only generated column
  @Column({ name: "created_at_ethiopian", insert: false, update: false })
  createdAtEthiopian: Date;
}
```

### Using in Queries

```typescript
import { AppDataSource } from "./data-source";
import { Order } from "./entities/Order";

const orderRepository = AppDataSource.getRepository(Order);

// Create - Ethiopian date is auto-generated
const order = orderRepository.create({
  customerName: "Abebe Kebede",
});
await orderRepository.save(order);

console.log(order.createdAtEthiopian); // Ethiopian timestamp!

// Raw query
const today = await AppDataSource.query(
  "SELECT current_ethiopian_date() as today"
);

// Query with Ethiopian date function
const orders = await AppDataSource.query(`
  SELECT *, to_ethiopian_date(created_at) as ethiopian_date
  FROM orders
  WHERE to_ethiopian_date(created_at) = '2018-04-23'
`);
```

### Using Query Builder

```typescript
const orders = await orderRepository
  .createQueryBuilder("order")
  .select("order.*")
  .addSelect("to_ethiopian_date(order.created_at)", "ethiopianDate")
  .getRawMany();
```

## Available Functions

| Function | Description |
|----------|-------------|
| `to_ethiopian_date(timestamp)` | Convert to Ethiopian date string (YYYY-MM-DD) |
| `from_ethiopian_date(text)` | Convert Ethiopian date to Gregorian timestamp |
| `to_ethiopian_timestamp(timestamp)` | Convert preserving time (for generated columns) |
| `current_ethiopian_date()` | Get current Ethiopian date |

## Links

- [GitHub Repository](https://github.com/HuluWZ/pg-ethiopian-calendar)
- [NPM Package](https://www.npmjs.com/package/@huluwz/pg-ethiopian-calendar)
- [TypeORM Docs](https://typeorm.io/)

