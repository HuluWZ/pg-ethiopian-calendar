# Ethiopian Calendar - TypeORM Demo

Blog platform demo showcasing Ethiopian calendar integration with TypeORM.

## Features

- ✅ Generated columns using TypeORM decorators
- ✅ Author and Post management
- ✅ Comments with Ethiopian timestamps
- ✅ Query posts by Ethiopian publication month
- ✅ Publish workflow with Ethiopian dates

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

# Run migration
npx typeorm migration:run -d src/data-source.ts

# Start server
npm run dev
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | (required) |
| `PORT` | Server port | `3003` |

## API Examples

### Create an Author

```bash
curl -X POST http://localhost:3003/authors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Tigist Bekele",
    "email": "tigist@example.com",
    "bio": "Ethiopian tech writer"
  }'
```

### Create a Post

```bash
curl -X POST http://localhost:3003/posts \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Understanding the Ethiopian Calendar",
    "content": "The Ethiopian calendar is 7-8 years behind the Gregorian calendar...",
    "authorId": 1
  }'
```

### Publish a Post

```bash
curl -X PATCH http://localhost:3003/posts/1/publish
```

Response includes Ethiopian publication date:

```json
{
  "id": 1,
  "title": "Understanding the Ethiopian Calendar",
  "status": "published",
  "publishedAt": "2026-01-04T12:00:00.000Z",
  "publishedAtEthiopian": "2018-04-26T12:00:00.000Z"
}
```

### Add a Comment

```bash
curl -X POST http://localhost:3003/posts/1/comments \
  -H "Content-Type: application/json" \
  -d '{
    "authorName": "Kebede",
    "content": "Great article! Very informative."
  }'
```

### Query by Ethiopian Month

```bash
# Get all posts published in Ethiopian month 4 (Tahsas), year 2018
curl http://localhost:3003/posts/published/ethiopian-month/2018/4
```

## Entity Example

```typescript
@Entity("posts")
export class Post {
  @Column({ name: "published_at", nullable: true })
  publishedAt?: Date;

  @Column({
    name: "published_at_ethiopian",
    type: "timestamp",
    generatedType: "STORED",
    asExpression: "to_ethiopian_timestamp(published_at)",
    nullable: true,
  })
  publishedAtEthiopian?: Date;
}
```

## Project Structure

```
src/
├── entity/
│   ├── Author.ts
│   ├── Post.ts
│   └── Comment.ts
├── migrations/
│   └── 1704384000000-Init.ts
├── data-source.ts
└── server.ts
```

