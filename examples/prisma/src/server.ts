import "dotenv/config";
import express, { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";

if (!process.env.DATABASE_URL) {
  console.error("❌ DATABASE_URL environment variable is required");
  console.error("   Copy env.example to .env and set your connection string");
  process.exit(1);
}

const app = express();
const prisma = new PrismaClient();
const PORT = process.env.PORT || 3001;

app.use(express.json());

// ============================================================================
// Ethiopian Calendar Endpoints
// ============================================================================

app.get("/ethiopian/today", async (_req: Request, res: Response) => {
  const result = await prisma.$queryRaw<[{ today: string }]>`
    SELECT to_ethiopian_date() as today
  `;
  res.json({ ethiopianDate: result[0].today });
});

app.get("/ethiopian/convert/:date", async (req: Request, res: Response) => {
  const { date } = req.params;
  try {
    const result = await prisma.$queryRaw<[{ ethiopian: string }]>`
      SELECT to_ethiopian_date(${date}::timestamp) as ethiopian
    `;
    res.json({ gregorian: date, ethiopian: result[0].ethiopian });
  } catch (error) {
    res.status(400).json({ error: "Invalid date format" });
  }
});

app.get("/ethiopian/to-gregorian/:date", async (req: Request, res: Response) => {
  const { date } = req.params;
  try {
    const result = await prisma.$queryRaw<[{ gregorian: Date }]>`
      SELECT from_ethiopian_date(${date}) as gregorian
    `;
    res.json({ ethiopian: date, gregorian: result[0].gregorian });
  } catch (error) {
    res.status(400).json({ error: "Invalid Ethiopian date" });
  }
});

// ============================================================================
// Customer Endpoints
// ============================================================================

app.get("/customers", async (_req: Request, res: Response) => {
  const customers = await prisma.customer.findMany({
    include: { orders: true },
  });
  res.json(customers);
});

app.post("/customers", async (req: Request, res: Response) => {
  const { name, email } = req.body;
  const customer = await prisma.customer.create({
    data: { name, email },
  });
  res.status(201).json(customer);
});

// ============================================================================
// Order Endpoints
// ============================================================================

app.get("/orders", async (_req: Request, res: Response) => {
  const orders = await prisma.order.findMany({
    include: { customer: true, items: true },
    orderBy: { createdAt: "desc" },
  });
  res.json(orders);
});

app.post("/orders", async (req: Request, res: Response) => {
  const { customerId, items } = req.body;

  const totalAmount = items.reduce(
    (sum: number, item: { price: number; quantity: number }) =>
      sum + item.price * item.quantity,
    0
  );

  const orderNumber = `ORD-${Date.now()}`;

  const order = await prisma.order.create({
    data: {
      orderNumber,
      customerId,
      totalAmount,
      items: { create: items },
    },
    include: { items: true, customer: true },
  });

  res.status(201).json(order);
});

app.patch("/orders/:id/status", async (req: Request, res: Response) => {
  const { id } = req.params;
  const { status } = req.body;

  const order = await prisma.order.update({
    where: { id: parseInt(id) },
    data: { status },
    include: { items: true },
  });

  res.json(order);
});

// ============================================================================
// Event Endpoints
// ============================================================================

app.get("/events", async (_req: Request, res: Response) => {
  const events = await prisma.event.findMany({
    orderBy: { eventDate: "asc" },
  });
  res.json(events);
});

app.post("/events", async (req: Request, res: Response) => {
  const { title, description, eventDate, ethiopianDate } = req.body;

  let parsedDate: Date;

  if (ethiopianDate) {
    const result = await prisma.$queryRaw<[{ gregorian: Date }]>`
      SELECT from_ethiopian_date(${ethiopianDate}) as gregorian
    `;
    parsedDate = result[0].gregorian;
  } else {
    parsedDate = new Date(eventDate);
  }

  const event = await prisma.event.create({
    data: { title, description, eventDate: parsedDate },
  });

  res.status(201).json(event);
});

// ============================================================================
// Query by Ethiopian Date Range
// ============================================================================

app.get("/orders/ethiopian-range", async (req: Request, res: Response) => {
  const { start, end } = req.query;

  if (!start || !end) {
    res.status(400).json({ error: "start and end Ethiopian dates required" });
    return;
  }

  const orders = await prisma.$queryRaw`
    SELECT o.*, c.name as customer_name
    FROM orders o
    JOIN customers c ON o.customer_id = c.id
    WHERE o.created_at_ethiopian >= to_ethiopian_timestamp(from_ethiopian_date(${start}::text)::timestamp)
      AND o.created_at_ethiopian < to_ethiopian_timestamp((from_ethiopian_date(${end}::text) + interval '1 day')::timestamp)
    ORDER BY o.created_at_ethiopian DESC
  `;

  res.json(orders);
});

// ============================================================================
// Server
// ============================================================================

app.listen(PORT, () => {
  console.log(`
╔═══════════════════════════════════════════════════════════╗
║     Ethiopian Calendar - Prisma Demo                      ║
╠═══════════════════════════════════════════════════════════╣
║  Server running on http://localhost:${PORT}                  ║
╠═══════════════════════════════════════════════════════════╣
║  Endpoints:                                               ║
║  • GET  /ethiopian/today          - Current Ethiopian date║
║  • GET  /ethiopian/convert/:date  - Gregorian → Ethiopian ║
║  • GET  /ethiopian/to-gregorian   - Ethiopian → Gregorian ║
║  • GET  /customers                - List customers        ║
║  • POST /customers                - Create customer       ║
║  • GET  /orders                   - List orders           ║
║  • POST /orders                   - Create order          ║
║  • GET  /events                   - List events           ║
║  • POST /events                   - Create event          ║
║  • GET  /orders/ethiopian-range   - Query by Eth. dates   ║
╚═══════════════════════════════════════════════════════════╝
  `);
});

