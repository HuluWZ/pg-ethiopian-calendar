import "dotenv/config";
import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import * as schema from "./schema.js";

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  console.error("❌ DATABASE_URL environment variable is required");
  console.error("   Copy env.example to .env and set your connection string");
  process.exit(1);
}

const client = postgres(connectionString);

export const db = drizzle(client, { schema });

