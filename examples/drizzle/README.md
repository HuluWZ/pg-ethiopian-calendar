# Ethiopian Calendar - Drizzle Demo

Event management demo showcasing Ethiopian calendar integration with Drizzle ORM.

## Features

- ✅ Generated columns with Drizzle schema
- ✅ Ethiopian holidays with Amharic names
- ✅ Appointment scheduling
- ✅ Invoice management with Ethiopian due dates
- ✅ Input dates in Ethiopian format
- ✅ **Ethiopian-only dates** (no Gregorian storage)

## Prerequisites

- **Node.js** >= 16.0.0
- **PostgreSQL** >= 12

## Quick Start

```bash
# Install dependencies
npm install

# Setup environment
cp env.example .env
# Edit .env with your DATABASE_URL

# Run migrations
npm run db:push
# Or: psql $DATABASE_URL -f drizzle/0000_init.sql

# Start server
npm run dev
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | (required) |
| `PORT` | Server port | `3002` |

## API Examples

### Seed Ethiopian Holidays

```bash
curl -X POST http://localhost:3002/holidays/seed
```

Response:

```json
{
  "holidays": [
    {
      "id": 1,
      "name": "Ethiopian New Year",
      "nameAmharic": "እንቁጣጣሽ",
      "holidayDate": "2025-09-11T00:00:00.000Z",
      "holidayDateEthiopian": "2018-01-01T00:00:00.000Z"
    }
  ]
}
```

### Create Appointment with Ethiopian Date

```bash
curl -X POST http://localhost:3002/appointments \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Business Meeting",
    "clientName": "Dawit Haile",
    "clientPhone": "+251911234567",
    "ethiopianDate": "2018-05-15",
    "duration": 90,
    "notes": "Discuss partnership"
  }'
```

### Create Invoice with Ethiopian Due Date

```bash
curl -X POST http://localhost:3002/invoices \
  -H "Content-Type: application/json" \
  -d '{
    "clientName": "ABC Company",
    "amount": "15000.00",
    "ethiopianDueDate": "2018-05-30"
  }'
```

### Mark Invoice as Paid

```bash
curl -X PATCH http://localhost:3002/invoices/1/pay
```

Response shows both payment timestamps:

```json
{
  "id": 1,
  "status": "paid",
  "paidAt": "2026-01-04T12:00:00.000Z",
  "paidAtEthiopian": "2018-04-26T12:00:00.000Z"
}
```

## Ethiopian-Only Timestamps (No Gregorian)

The `notes` table demonstrates storing **only Ethiopian timestamps** - no Gregorian storage at all:

```bash
# Create a note - created_at defaults to current Ethiopian timestamp
curl -X POST http://localhost:3002/notes \
  -H "Content-Type: application/json" \
  -d '{"title": "Meeting Notes", "content": "Discussed Q1 goals"}'
```

Response:

```json
{
  "id": 1,
  "title": "Meeting Notes",
  "content": "Discussed Q1 goals",
  "category": "general",
  "createdAt": "2018-04-26T14:30:00.000Z"  // Ethiopian timestamp only!
}
```

```bash
# Query notes by Ethiopian date
curl http://localhost:3002/notes/by-date/2018-04-26
```

### Schema

```typescript
export const notes = pgTable("notes", {
  id: serial("id").primaryKey(),
  title: text("title").notNull(),
  content: text("content"),
  // Ethiopian timestamp only - defaults to current Ethiopian timestamp
  createdAt: timestamp("created_at").default(sql`to_ethiopian_timestamp()`).notNull(),
});
```

### SQL

```sql
CREATE TABLE "notes" (
    "id" SERIAL PRIMARY KEY,
    "title" TEXT NOT NULL,
    "content" TEXT,
    "created_at" TIMESTAMP NOT NULL DEFAULT to_ethiopian_timestamp()
);
```

## Schema Highlights

```typescript
import { pgTable, timestamp } from "drizzle-orm/pg-core";
import { sql } from "drizzle-orm";

// Option 1: Both Gregorian and Ethiopian (generated column)
export const invoices = pgTable("invoices", {
  dueDate: timestamp("due_date").notNull(),
  dueDateEthiopian: timestamp("due_date_ethiopian").generatedAlwaysAs(
    sql`to_ethiopian_timestamp(due_date)`
  ),
});

// Option 2: Ethiopian only (no Gregorian storage)
export const notes = pgTable("notes", {
  createdAt: timestamp("created_at").default(sql`to_ethiopian_timestamp()`).notNull(),
});
```

## Project Structure

```
drizzle/
└── 0000_init.sql          # Functions + Tables
src/
├── schema.ts              # Drizzle schema
├── db.ts                  # Database connection
└── server.ts              # Express API
```

