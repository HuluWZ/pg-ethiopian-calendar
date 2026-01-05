# Ethiopian Calendar Examples

Real-world examples demonstrating Ethiopian calendar integration with popular ORMs.

## Prerequisites

- **Node.js** >= 16.0.0
- **PostgreSQL** >= 12

## Examples

| Example | ORM | Use Case | Port |
|---------|-----|----------|------|
| [prisma/](./prisma/) | Prisma | E-commerce orders | 3001 |
| [drizzle/](./drizzle/) | Drizzle | Event management | 3002 |
| [typeorm/](./typeorm/) | TypeORM | Blog platform | 3003 |

## Quick Start

Each example follows the same pattern:

```bash
cd examples/<orm>

# Install dependencies
npm install

# Setup environment
cp env.example .env
# Edit .env with your DATABASE_URL

# Run migrations
# Prisma: npx prisma migrate deploy
# Drizzle: npm run db:push or psql -f drizzle/0000_init.sql
# TypeORM: npx typeorm migration:run -d src/data-source.ts

# Start dev server
npm run dev
```

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection | `postgresql://user:pass@localhost:5432/db` |
| `PORT` | Server port | `3001`, `3002`, `3003` |

## Features Demonstrated

### Generated Columns

All examples show how to create PostgreSQL generated columns that automatically convert Gregorian dates to Ethiopian:

```sql
created_at_ethiopian TIMESTAMP GENERATED ALWAYS AS 
    (to_ethiopian_timestamp(created_at)) STORED
```

### Input Ethiopian Dates

Create records using Ethiopian date input:

```bash
# Prisma example - create event with Ethiopian date
curl -X POST http://localhost:3001/events \
  -H "Content-Type: application/json" \
  -d '{"title": "Meeting", "ethiopianDate": "2018-05-15"}'

# Drizzle example - create holiday
curl -X POST http://localhost:3002/holidays \
  -H "Content-Type: application/json" \
  -d '{"name": "New Year", "ethiopianDate": "2019-01-01"}'
```

### Ethiopian-Only Timestamps (No Gregorian Storage)

Store timestamps in Ethiopian format only - no Gregorian storage:

```bash
# Drizzle notes example - created_at defaults to current Ethiopian timestamp
curl -X POST http://localhost:3002/notes \
  -H "Content-Type: application/json" \
  -d '{"title": "Meeting Notes", "content": "Discussed goals"}'

# Response: {"id": 1, "title": "Meeting Notes", "createdAt": "2018-04-26T14:30:00.000Z"}
```

```sql
-- SQL default using to_ethiopian_timestamp()
CREATE TABLE notes (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT to_ethiopian_timestamp()
);
```

### Query by Ethiopian Date

```bash
# Get orders in Ethiopian date range
curl "http://localhost:3001/orders/ethiopian-range?start=2018-04-01&end=2018-04-30"

# Get posts by Ethiopian month
curl http://localhost:3003/posts/published/ethiopian-month/2018/4
```

## Common API Endpoints

All examples include these Ethiopian calendar endpoints:

| Endpoint | Description |
|----------|-------------|
| `GET /ethiopian/today` | Current Ethiopian date |
| `GET /ethiopian/convert/:date` | Convert Gregorian → Ethiopian |
| `GET /ethiopian/to-gregorian/:date` | Convert Ethiopian → Gregorian |

## Database Setup

Each example requires PostgreSQL. You can:

1. **Local PostgreSQL**
   ```bash
   createdb ethiopian_demo
   ```

2. **Docker**
   ```bash
   docker run -d --name postgres \
     -e POSTGRES_PASSWORD=postgres \
     -p 5432:5432 \
     postgres:16
   ```

3. **Cloud PostgreSQL** (Neon, Supabase, Railway, etc.)
   - Create a new database
   - Copy the connection string

## Project Structure

```
examples/
├── README.md           # This file
├── prisma/
│   ├── prisma/
│   │   ├── schema.prisma
│   │   └── migrations/
│   ├── src/server.ts
│   └── README.md
├── drizzle/
│   ├── drizzle/
│   │   └── 0000_init.sql
│   ├── src/
│   │   ├── schema.ts
│   │   ├── db.ts
│   │   └── server.ts
│   └── README.md
└── typeorm/
    ├── src/
    │   ├── entity/
    │   ├── migrations/
    │   └── server.ts
    └── README.md
```

## Need Help?

- [Main Documentation](../README.md)
- [NPM Package](../npm/README.md)
- [Issue Tracker](https://github.com/HuluWZ/pg-ethiopian-calendar/issues)

