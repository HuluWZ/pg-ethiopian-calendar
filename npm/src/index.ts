/**
 * @huluwz/pg-ethiopian-calendar
 *
 * Ethiopian calendar functions for PostgreSQL.
 * Works with Prisma, Drizzle, TypeORM, Sequelize, and any ORM.
 *
 * @author Hulunlante Worku <hulunlante.w@gmail.com>
 * @license PostgreSQL
 */

import * as fs from "fs";
import * as path from "path";

export type SupportedORM =
  | "prisma"
  | "drizzle"
  | "typeorm"
  | "sequelize"
  | "knex"
  | "kysely"
  | "mikro-orm"
  | "raw";

/**
 * Get the path to the SQL migration file
 * @returns Absolute path to the SQL file
 */
export function getSqlPath(): string {
  return path.join(__dirname, "..", "sql", "ethiopian_calendar.sql");
}

/**
 * Get the SQL content as a string
 * @returns The SQL migration content
 */
export function getSql(): string {
  return fs.readFileSync(getSqlPath(), "utf8");
}

/**
 * Get the path to the documentation for a specific ORM
 * @param orm - The ORM name
 * @returns Absolute path to the documentation file
 */
export function getDocsPath(orm: SupportedORM): string {
  return path.join(__dirname, "..", "docs", `${orm.toLowerCase()}.md`);
}

/**
 * Check if a specific ORM is installed in the project
 * @param orm - The ORM name to check
 * @returns True if the ORM is installed
 */
export function isOrmInstalled(orm: SupportedORM): boolean {
  const ormPackages: Record<SupportedORM, string> = {
    prisma: "@prisma/client",
    drizzle: "drizzle-orm",
    typeorm: "typeorm",
    sequelize: "sequelize",
    knex: "knex",
    kysely: "kysely",
    "mikro-orm": "@mikro-orm/core",
    raw: "pg",
  };

  try {
    require.resolve(ormPackages[orm]);
    return true;
  } catch {
    return false;
  }
}

/**
 * Detect which ORM is being used in the current project
 * @returns The detected ORM or null if none found
 */
export function detectOrm(): SupportedORM | null {
  const ormsToCheck: SupportedORM[] = [
    "prisma",
    "drizzle",
    "typeorm",
    "sequelize",
    "knex",
    "kysely",
    "mikro-orm",
    "raw",
  ];

  for (const orm of ormsToCheck) {
    if (isOrmInstalled(orm)) {
      return orm;
    }
  }

  return null;
}

/**
 * Get migration output path for a specific ORM
 * @param orm - The ORM name
 * @param migrationName - Optional custom migration name
 * @returns Suggested migration file path
 */
export function getMigrationPath(
  orm: SupportedORM,
  migrationName: string = "ethiopian_calendar"
): string {
  const timestamp = new Date()
    .toISOString()
    .replace(/[-:T]/g, "")
    .slice(0, 14);

  switch (orm) {
    case "prisma":
      return path.join(
        "prisma",
        "migrations",
        `${timestamp}_${migrationName}`,
        "migration.sql"
      );
    case "drizzle":
      return path.join("drizzle", `${timestamp}_${migrationName}.sql`);
    case "typeorm":
      return path.join(
        "src",
        "migrations",
        `${timestamp}-${migrationName}.ts`
      );
    case "sequelize":
      return path.join("migrations", `${timestamp}-${migrationName}.js`);
    case "knex":
      return path.join("migrations", `${timestamp}_${migrationName}.js`);
    case "kysely":
      return path.join("migrations", `${timestamp}_${migrationName}.ts`);
    case "mikro-orm":
      return path.join(
        "src",
        "migrations",
        `Migration${timestamp}_${migrationName}.ts`
      );
    case "raw":
    default:
      return `${migrationName}.sql`;
  }
}

// Export paths directly for convenience
export const sqlPath = path.join(__dirname, "..", "sql", "ethiopian_calendar.sql");
export const docsDir = path.join(__dirname, "..", "docs");

