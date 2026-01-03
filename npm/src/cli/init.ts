#!/usr/bin/env node
/**
 * CLI for Ethiopian Calendar PostgreSQL migrations
 * @example npx ethiopian-calendar init prisma
 */

import { mkdirSync, existsSync, writeFileSync } from "fs";
import { dirname } from "path";
import { getSql, detectOrm, getMigrationPath, listMigrations, VERSION, type SupportedORM } from "../index";

const fmt = {
  reset: "\x1b[0m",
  bold: "\x1b[1m",
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  cyan: "\x1b[36m",
} as const;

const log = console.log;
const print = {
  info: (msg: string) => log(`${fmt.blue}ℹ${fmt.reset} ${msg}`),
  success: (msg: string) => log(`${fmt.green}✔${fmt.reset} ${msg}`),
  error: (msg: string) => log(`${fmt.red}✖${fmt.reset} ${msg}`),
};

const DROP_FUNCTIONS_SQL = `
DROP FUNCTION IF EXISTS pg_ethiopian_to_datetime(timestamp);
DROP FUNCTION IF EXISTS pg_ethiopian_to_timestamp(timestamp);
DROP FUNCTION IF EXISTS pg_ethiopian_from_date(text);
DROP FUNCTION IF EXISTS pg_ethiopian_to_date(timestamp);
DROP FUNCTION IF EXISTS ethiopian_calendar_version();
DROP FUNCTION IF EXISTS current_ethiopian_date();
DROP FUNCTION IF EXISTS to_ethiopian_datetime(timestamp);
DROP FUNCTION IF EXISTS to_ethiopian_timestamp();
DROP FUNCTION IF EXISTS to_ethiopian_timestamp(timestamp);
DROP FUNCTION IF EXISTS from_ethiopian_date(text);
DROP FUNCTION IF EXISTS to_ethiopian_date();
DROP FUNCTION IF EXISTS to_ethiopian_date(timestamp);
DROP FUNCTION IF EXISTS _ethiopian_to_jdn(integer, integer, integer);
DROP FUNCTION IF EXISTS _jdn_to_ethiopian(integer);
DROP FUNCTION IF EXISTS _jdn_to_gregorian(integer);
DROP FUNCTION IF EXISTS _gregorian_to_jdn(integer, integer, integer);
`.trim();

function generateTypeOrmMigration(sql: string): string {
  const className = `EthiopianCalendar${Date.now()}`;
  return `import { MigrationInterface, QueryRunner } from "typeorm";

export class ${className} implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(\`${sql.replace(/`/g, "\\`")}\`);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(\`${DROP_FUNCTIONS_SQL}\`);
  }
}
`;
}

function writeMigration(orm: SupportedORM, outputPath: string): void {
  const dir = dirname(outputPath);
  if (!existsSync(dir)) {
    mkdirSync(dir, { recursive: true });
  }

  const sql = getSql();
  const content = orm === "typeorm" ? generateTypeOrmMigration(sql) : sql;
  writeFileSync(outputPath, content);
}

const VALID_ORMS: SupportedORM[] = ["prisma", "drizzle", "typeorm", "raw"];

const NEXT_STEPS: Record<SupportedORM, string[]> = {
  prisma: ["npx prisma migrate dev"],
  drizzle: ["npx drizzle-kit migrate"],
  typeorm: ["npx typeorm migration:run -d src/data-source.ts"],
  raw: ["psql -d DATABASE -f ethiopian_calendar.sql"],
};

function showHelp(): void {
  log(`
${fmt.cyan}${fmt.bold}Ethiopian Calendar for PostgreSQL${fmt.reset} ${fmt.yellow}v${VERSION}${fmt.reset}

${fmt.bold}Usage:${fmt.reset}
  npx ethiopian-calendar init [orm]
  npx ethiopian-calendar version
  npx ethiopian-calendar migrations

${fmt.bold}ORMs:${fmt.reset}
  prisma, drizzle, typeorm, raw

${fmt.bold}Examples:${fmt.reset}
  npx ethiopian-calendar init          ${fmt.cyan}# auto-detect${fmt.reset}
  npx ethiopian-calendar init prisma
`);
}

function showVersion(): void {
  log(`${fmt.bold}v${VERSION}${fmt.reset}`);
  log(`\nCheck database: ${fmt.cyan}SELECT ethiopian_calendar_version();${fmt.reset}\n`);
}

function showMigrations(): void {
  const migrations = listMigrations();
  log(`\n${fmt.bold}Available Upgrades:${fmt.reset}`);
  if (migrations.length === 0) {
    log("  None\n");
  } else {
    migrations.forEach((m) => log(`  ${m.from} → ${m.to}`));
    log("");
  }
}

function initMigration(ormArg?: string): void {
  let orm: SupportedORM;

  if (ormArg) {
    if (!VALID_ORMS.includes(ormArg as SupportedORM)) {
      print.error(`Unknown ORM: ${ormArg}`);
      log(`\nSupported: ${VALID_ORMS.join(", ")}\n`);
      process.exit(1);
    }
    orm = ormArg as SupportedORM;
    print.info(`Using: ${orm}`);
  } else {
    print.info("Detecting ORM...");
    const detected = detectOrm();
    if (!detected) {
      print.error("No ORM detected");
      log(`\nSpecify one: npx ethiopian-calendar init <${VALID_ORMS.join("|")}>\n`);
      process.exit(1);
    }
    orm = detected;
    print.success(`Detected: ${orm}`);
  }

  const outputPath = getMigrationPath(orm);

  try {
    writeMigration(orm, outputPath);
    print.success(`Created: ${outputPath}`);
  } catch (err) {
    print.error(`Failed: ${err instanceof Error ? err.message : err}`);
    process.exit(1);
  }

  log(`\n${fmt.bold}Next:${fmt.reset} ${NEXT_STEPS[orm][0]}`);
  log(`\n${fmt.bold}Functions:${fmt.reset}`);
  log(`  to_ethiopian_date()          → text       ${fmt.cyan}# current date${fmt.reset}`);
  log(`  to_ethiopian_date(timestamp) → text`);
  log(`  from_ethiopian_date(text)    → timestamp`);
  log(`  to_ethiopian_timestamp()     → timestamp  ${fmt.cyan}# current timestamp${fmt.reset}`);
  log(`  to_ethiopian_timestamp(ts)   → timestamp\n`);
}

const [cmd, arg] = process.argv.slice(2);

switch (cmd) {
  case undefined:
  case "help":
  case "--help":
  case "-h":
    showHelp();
    break;
  case "version":
  case "--version":
  case "-v":
    showVersion();
    break;
  case "migrations":
    showMigrations();
    break;
  case "init":
    initMigration(arg);
    break;
  default:
    print.error(`Unknown command: ${cmd}`);
    showHelp();
    process.exit(1);
}
