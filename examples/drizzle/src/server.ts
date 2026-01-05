import express, { Request, Response } from "express";
import { db } from "./db.js";
import { holidays, appointments, invoices, notes } from "./schema.js";
import { eq, sql, desc, asc } from "drizzle-orm";

const app = express();
const PORT = process.env.PORT || 3002;

app.use(express.json());

// ============================================================================
// Ethiopian Calendar Endpoints
// ============================================================================

app.get("/ethiopian/today", async (_req: Request, res: Response) => {
  const result = await db.execute<{ today: string }>(
    sql`SELECT to_ethiopian_date() as today`
  );
  res.json({ ethiopianDate: result[0].today });
});

app.get("/ethiopian/now", async (_req: Request, res: Response) => {
  const result = await db.execute<{ now: Date }>(
    sql`SELECT to_ethiopian_timestamp() as now`
  );
  res.json({ ethiopianTimestamp: result[0].now });
});

// ============================================================================
// Holiday Endpoints
// ============================================================================

app.get("/holidays", async (_req: Request, res: Response) => {
  const result = await db.select().from(holidays).orderBy(asc(holidays.holidayDate));
  res.json(result);
});

app.post("/holidays", async (req: Request, res: Response) => {
  const { name, nameAmharic, holidayDate, type, description, ethiopianDate } = req.body;

  let parsedDate: Date;
  if (ethiopianDate) {
    const converted = await db.execute<{ gregorian: Date }>(
      sql`SELECT from_ethiopian_date(${ethiopianDate}) as gregorian`
    );
    parsedDate = converted[0].gregorian;
  } else {
    parsedDate = new Date(holidayDate);
  }

  const [holiday] = await db
    .insert(holidays)
    .values({ name, nameAmharic, holidayDate: parsedDate, type, description })
    .returning();

  res.status(201).json(holiday);
});

app.post("/holidays/seed", async (_req: Request, res: Response) => {
  const ethiopianHolidays = [
    { name: "Ethiopian New Year", nameAmharic: "እንቁጣጣሽ", ethiopianDate: "2018-01-01", type: "national" },
    { name: "Finding of True Cross", nameAmharic: "መስቀል", ethiopianDate: "2018-01-17", type: "religious" },
    { name: "Ethiopian Christmas", nameAmharic: "ገና", ethiopianDate: "2018-04-29", type: "religious" },
    { name: "Epiphany", nameAmharic: "ጥምቀት", ethiopianDate: "2018-05-11", type: "religious" },
    { name: "Victory of Adwa", nameAmharic: "አድዋ", ethiopianDate: "2018-06-23", type: "national" },
  ];

  const inserted = [];
  for (const h of ethiopianHolidays) {
    const converted = await db.execute<{ gregorian: Date }>(
      sql`SELECT from_ethiopian_date(${h.ethiopianDate}) as gregorian`
    );
    const [holiday] = await db
      .insert(holidays)
      .values({
        name: h.name,
        nameAmharic: h.nameAmharic,
        holidayDate: converted[0].gregorian,
        type: h.type,
      })
      .returning();
    inserted.push(holiday);
  }

  res.status(201).json({ message: "Seeded Ethiopian holidays", holidays: inserted });
});

// ============================================================================
// Appointment Endpoints
// ============================================================================

app.get("/appointments", async (_req: Request, res: Response) => {
  const result = await db
    .select()
    .from(appointments)
    .orderBy(asc(appointments.appointmentTime));
  res.json(result);
});

app.post("/appointments", async (req: Request, res: Response) => {
  const { title, clientName, clientPhone, appointmentTime, duration, notes, ethiopianDate } =
    req.body;

  let parsedTime: Date;
  if (ethiopianDate) {
    const converted = await db.execute<{ gregorian: Date }>(
      sql`SELECT from_ethiopian_date(${ethiopianDate}) as gregorian`
    );
    parsedTime = converted[0].gregorian;
  } else {
    parsedTime = new Date(appointmentTime);
  }

  const [appointment] = await db
    .insert(appointments)
    .values({ title, clientName, clientPhone, appointmentTime: parsedTime, duration, notes })
    .returning();

  res.status(201).json(appointment);
});

app.patch("/appointments/:id/status", async (req: Request, res: Response) => {
  const { id } = req.params;
  const { status } = req.body;

  const [updated] = await db
    .update(appointments)
    .set({ status })
    .where(eq(appointments.id, parseInt(id)))
    .returning();

  res.json(updated);
});

// ============================================================================
// Invoice Endpoints
// ============================================================================

app.get("/invoices", async (_req: Request, res: Response) => {
  const result = await db.select().from(invoices).orderBy(desc(invoices.createdAt));
  res.json(result);
});

app.post("/invoices", async (req: Request, res: Response) => {
  const { clientName, amount, dueDate, ethiopianDueDate } = req.body;

  let parsedDueDate: Date;
  if (ethiopianDueDate) {
    const converted = await db.execute<{ gregorian: Date }>(
      sql`SELECT from_ethiopian_date(${ethiopianDueDate}) as gregorian`
    );
    parsedDueDate = converted[0].gregorian;
  } else {
    parsedDueDate = new Date(dueDate);
  }

  const invoiceNumber = `INV-${Date.now()}`;

  const [invoice] = await db
    .insert(invoices)
    .values({ invoiceNumber, clientName, amount, dueDate: parsedDueDate })
    .returning();

  res.status(201).json(invoice);
});

app.patch("/invoices/:id/pay", async (req: Request, res: Response) => {
  const { id } = req.params;

  const [updated] = await db
    .update(invoices)
    .set({ status: "paid", paidAt: new Date() })
    .where(eq(invoices.id, parseInt(id)))
    .returning();

  res.json(updated);
});

// ============================================================================
// Notes Endpoints - Ethiopian dates ONLY (no Gregorian)
// ============================================================================

app.get("/notes", async (_req: Request, res: Response) => {
  const result = await db.select().from(notes).orderBy(desc(notes.createdAt));
  res.json(result);
});

app.post("/notes", async (req: Request, res: Response) => {
  const { title, content, category } = req.body;

  // created_at automatically defaults to to_ethiopian_date() in the database
  const [note] = await db
    .insert(notes)
    .values({ title, content, category })
    .returning();

  res.status(201).json(note);
});

app.get("/notes/by-date/:ethiopianDate", async (req: Request, res: Response) => {
  const { ethiopianDate } = req.params; // Format: 2018-04-26

  // Query notes where Ethiopian timestamp falls on this date
  const result = await db.execute<typeof notes.$inferSelect>(sql`
    SELECT * FROM notes 
    WHERE created_at::date = ${ethiopianDate}::date
    ORDER BY created_at DESC
  `);

  res.json(result);
});

// ============================================================================
// Server
// ============================================================================

app.listen(PORT, () => {
  console.log(`
╔═══════════════════════════════════════════════════════════╗
║     Ethiopian Calendar - Drizzle Demo                     ║
╠═══════════════════════════════════════════════════════════╣
║  Server running on http://localhost:${PORT}                  ║
╠═══════════════════════════════════════════════════════════╣
║  Endpoints:                                               ║
║  • GET  /ethiopian/today          - Current Ethiopian date║
║  • GET  /ethiopian/now            - Current Eth timestamp ║
║  • GET  /holidays                 - List holidays         ║
║  • POST /holidays                 - Create holiday        ║
║  • POST /holidays/seed            - Seed Eth holidays     ║
║  • GET  /appointments             - List appointments     ║
║  • POST /appointments             - Create appointment    ║
║  • GET  /invoices                 - List invoices         ║
║  • POST /invoices                 - Create invoice        ║
║  • PATCH /invoices/:id/pay        - Mark as paid          ║
║  • GET  /notes                    - List notes (Eth only) ║
║  • POST /notes                    - Create note           ║
║  • GET  /notes/by-date/:date      - Notes by Eth date     ║
╚═══════════════════════════════════════════════════════════╝
  `);
});

