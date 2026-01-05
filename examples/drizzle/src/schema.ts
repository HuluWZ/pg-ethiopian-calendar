import {
  pgTable,
  serial,
  text,
  timestamp,
  integer,
  decimal,
  index,
} from "drizzle-orm/pg-core";
import { sql } from "drizzle-orm";

// Holidays table - Ethiopian public holidays
export const holidays = pgTable(
  "holidays",
  {
    id: serial("id").primaryKey(),
    name: text("name").notNull(),
    nameAmharic: text("name_amharic"),
    holidayDate: timestamp("holiday_date").notNull(),
    holidayDateEthiopian: timestamp("holiday_date_ethiopian").generatedAlwaysAs(
      sql`to_ethiopian_timestamp(holiday_date)`
    ),
    type: text("type").notNull().default("national"),
    description: text("description"),
    createdAt: timestamp("created_at").defaultNow().notNull(),
  },
  (table) => ({
    holidayDateEthIdx: index("idx_holidays_eth_date").on(table.holidayDateEthiopian),
  })
);

// Appointments table
export const appointments = pgTable(
  "appointments",
  {
    id: serial("id").primaryKey(),
    title: text("title").notNull(),
    clientName: text("client_name").notNull(),
    clientPhone: text("client_phone"),
    appointmentTime: timestamp("appointment_time").notNull(),
    appointmentTimeEthiopian: timestamp("appointment_time_ethiopian").generatedAlwaysAs(
      sql`to_ethiopian_timestamp(appointment_time)`
    ),
    duration: integer("duration").default(60), // minutes
    status: text("status").notNull().default("scheduled"),
    notes: text("notes"),
    createdAt: timestamp("created_at").defaultNow().notNull(),
    createdAtEthiopian: timestamp("created_at_ethiopian").generatedAlwaysAs(
      sql`to_ethiopian_timestamp(created_at)`
    ),
  },
  (table) => ({
    appointmentTimeIdx: index("idx_appointments_time").on(table.appointmentTime),
    appointmentTimeEthIdx: index("idx_appointments_eth_time").on(
      table.appointmentTimeEthiopian
    ),
  })
);

// Invoices table
export const invoices = pgTable("invoices", {
  id: serial("id").primaryKey(),
  invoiceNumber: text("invoice_number").notNull().unique(),
  clientName: text("client_name").notNull(),
  amount: decimal("amount", { precision: 10, scale: 2 }).notNull(),
  status: text("status").notNull().default("pending"),
  dueDate: timestamp("due_date").notNull(),
  dueDateEthiopian: timestamp("due_date_ethiopian").generatedAlwaysAs(
    sql`to_ethiopian_timestamp(due_date)`
  ),
  paidAt: timestamp("paid_at"),
  paidAtEthiopian: timestamp("paid_at_ethiopian").generatedAlwaysAs(
    sql`to_ethiopian_timestamp(paid_at)`
  ),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  createdAtEthiopian: timestamp("created_at_ethiopian").generatedAlwaysAs(
    sql`to_ethiopian_timestamp(created_at)`
  ),
});

// Notes table - Ethiopian dates ONLY (no Gregorian)
// Uses to_ethiopian_timestamp() as default for created_at
export const notes = pgTable("notes", {
  id: serial("id").primaryKey(),
  title: text("title").notNull(),
  content: text("content"),
  category: text("category").default("general"),
  // Ethiopian timestamp only - defaults to current Ethiopian timestamp
  createdAt: timestamp("created_at").default(sql`to_ethiopian_timestamp()`).notNull(),
});

export type Holiday = typeof holidays.$inferSelect;
export type NewHoliday = typeof holidays.$inferInsert;
export type Appointment = typeof appointments.$inferSelect;
export type NewAppointment = typeof appointments.$inferInsert;
export type Invoice = typeof invoices.$inferSelect;
export type NewInvoice = typeof invoices.$inferInsert;
export type Note = typeof notes.$inferSelect;
export type NewNote = typeof notes.$inferInsert;

