import { readFileSync, existsSync, readdirSync } from "fs";
import { join, dirname } from "path";

export const VERSION = "1.1.0";

export type SupportedORM = "prisma" | "drizzle" | "typeorm" | "raw";

const ORM_PACKAGES: Record<Exclude<SupportedORM, "raw">, string> = {
  prisma: "@prisma/client",
  drizzle: "drizzle-orm",
  typeorm: "typeorm",
};

const SQL_DIR = join(dirname(__dirname), "sql");
const DOCS_DIR = join(dirname(__dirname), "docs");

/** Returns the full SQL migration content */
export function getSql(): string {
  return readFileSync(join(SQL_DIR, "ethiopian_calendar.sql"), "utf8");
}

/** Returns path to the SQL migration file */
export function getSqlPath(): string {
  return join(SQL_DIR, "ethiopian_calendar.sql");
}

/** Returns path to ORM-specific documentation */
export function getDocsPath(orm: SupportedORM): string {
  return join(DOCS_DIR, `${orm}.md`);
}

/** Checks if an ORM package is installed */
export function isOrmInstalled(orm: Exclude<SupportedORM, "raw">): boolean {
  try {
    require.resolve(ORM_PACKAGES[orm]);
    return true;
  } catch {
    return false;
  }
}

/** Auto-detects installed ORM, returns null if none found */
export function detectOrm(): Exclude<SupportedORM, "raw"> | null {
  const orms = Object.keys(ORM_PACKAGES) as Exclude<SupportedORM, "raw">[];
  return orms.find(isOrmInstalled) ?? null;
}

/** Generates timestamp for migration filenames */
function timestamp(): string {
  return new Date().toISOString().replace(/[-:T]/g, "").slice(0, 14);
}

/** Returns the migration output path for the specified ORM */
export function getMigrationPath(orm: SupportedORM, name = "ethiopian_calendar"): string {
  const ts = timestamp();
  const paths: Record<SupportedORM, string> = {
    prisma: join("prisma", "migrations", `${ts}_${name}`, "migration.sql"),
    drizzle: join("drizzle", `${ts}_${name}.sql`),
    typeorm: join("src", "migrations", `${ts}-${name}.ts`),
    raw: `${name}.sql`,
  };
  return paths[orm];
}

/** Returns path to version upgrade migration, or null if not found */
export function getUpgradePath(from: string, to: string): string | null {
  const file = join(SQL_DIR, "migrations", `${from}_to_${to}.sql`);
  return existsSync(file) ? file : null;
}

/** Returns upgrade migration SQL content, or null if not found */
export function getUpgradeSql(from: string, to: string): string | null {
  const file = getUpgradePath(from, to);
  return file ? readFileSync(file, "utf8") : null;
}

export interface Migration {
  from: string;
  to: string;
  path: string;
}

/** Lists all available upgrade migrations */
export function listMigrations(): Migration[] {
  const dir = join(SQL_DIR, "migrations");
  if (!existsSync(dir)) return [];

  const pattern = /^(\d+\.\d+\.\d+)_to_(\d+\.\d+\.\d+)\.sql$/;

  return readdirSync(dir)
    .map((file) => {
      const match = file.match(pattern);
      return match ? { from: match[1], to: match[2], path: join(dir, file) } : null;
    })
    .filter((m): m is Migration => m !== null);
}

/** SQL query to check installed version in database */
export function getVersionCheckSql(): string {
  return `SELECT COALESCE(
    (SELECT proname FROM pg_proc WHERE proname = 'ethiopian_calendar_version' LIMIT 1),
    NULL
  )::text AS installed, '${VERSION}' AS latest;`;
}
