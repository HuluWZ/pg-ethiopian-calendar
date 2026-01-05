# Ethiopian Calendar - Prisma Demo

E-commerce demo showcasing Ethiopian calendar integration with Prisma ORM.

## Features

- ✅ Generated columns for automatic Ethiopian timestamps
- ✅ Customer and Order management
- ✅ Event scheduling with Ethiopian dates
- ✅ Query by Ethiopian date range
- ✅ Convert between Gregorian and Ethiopian calendars

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
npx prisma migrate deploy
npx prisma generate

# Start server
npm run dev
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | (required) |
| `PORT` | Server port | `3001` |

## API Examples

### Get Today's Ethiopian Date

```bash
curl http://localhost:3001/ethiopian/today
# {"ethiopianDate":"2018-04-26"}
```

### Create a Customer

```bash
curl -X POST http://localhost:3001/customers \
  -H "Content-Type: application/json" \
  -d '{"name": "Abebe Kebede", "email": "abebe@example.com"}'
```

### Create an Order

```bash
curl -X POST http://localhost:3001/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": 1,
    "items": [
      {"product": "Coffee Beans", "quantity": 2, "price": 150},
      {"product": "Honey", "quantity": 1, "price": 200}
    ]
  }'
```

Response includes Ethiopian timestamps:

```json
{
  "id": 1,
  "orderNumber": "ORD-1704384000000",
  "totalAmount": "500.00",
  "createdAt": "2026-01-04T12:00:00.000Z",
  "createdAtEthiopian": "2018-04-26T12:00:00.000Z",
  "items": [...]
}
```

### Create Event with Ethiopian Date

```bash
curl -X POST http://localhost:3001/events \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Ethiopian New Year",
    "description": "Enkutatash celebration",
    "ethiopianDate": "2019-01-01"
  }'
```

### Query Orders by Ethiopian Date Range

```bash
curl "http://localhost:3001/orders/ethiopian-range?start=2018-04-01&end=2018-04-30"
```

## Database Schema

The schema uses PostgreSQL generated columns for automatic Ethiopian date conversion:

```sql
CREATE TABLE "orders" (
    "id" SERIAL PRIMARY KEY,
    "created_at" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at_ethiopian" TIMESTAMP GENERATED ALWAYS AS 
        (to_ethiopian_timestamp("created_at")) STORED
);
```

## Project Structure

```
prisma/
├── migrations/
│   └── 00000000000000_init/
│       └── migration.sql    # Functions + Tables
└── schema.prisma
src/
└── server.ts                # Express API
```

