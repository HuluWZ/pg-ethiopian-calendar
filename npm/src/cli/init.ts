#!/usr/bin/env node

/**
 * CLI for initializing Ethiopian calendar migrations
 *
 * Usage:
 *   npx @huluwz/pg-ethiopian-calendar init [orm]
 *   npx ethiopian-calendar init [orm]
 *
 * Examples:
 *   npx ethiopian-calendar init           # Auto-detect ORM
 *   npx ethiopian-calendar init prisma    # Use Prisma
 *   npx ethiopian-calendar init drizzle   # Use Drizzle
 */

import * as fs from "fs";
import * as path from "path";
import {
  getSql,
  getSqlPath,
  detectOrm,
  getMigrationPath,
  type SupportedORM,
} from "../index";

// ANSI color codes
const colors = {
  reset: "\x1b[0m",
  bright: "\x1b[1m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  cyan: "\x1b[36m",
  red: "\x1b[31m",
};

function log(message: string): void {
  console.log(message);
}

function success(message: string): void {
  console.log(`${colors.green}✔${colors.reset} ${message}`);
}

function info(message: string): void {
  console.log(`${colors.blue}ℹ${colors.reset} ${message}`);
}

function warn(message: string): void {
  console.log(`${colors.yellow}⚠${colors.reset} ${message}`);
}

function error(message: string): void {
  console.log(`${colors.red}✖${colors.reset} ${message}`);
}

function printBanner(): void {
  log("");
  log(
    `${colors.cyan}${colors.bright}Ethiopian Calendar for PostgreSQL${colors.reset}`
  );
  log(`${colors.cyan}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}`);
  log("");
}

function printUsage(): void {
  log(`${colors.bright}Usage:${colors.reset}`);
  log("  npx ethiopian-calendar init [orm]");
  log("");
  log(`${colors.bright}Supported ORMs:${colors.reset}`);
  log("  prisma, drizzle, typeorm, sequelize, knex, kysely, mikro-orm, raw");
  log("");
  log(`${colors.bright}Examples:${colors.reset}`);
  log("  npx ethiopian-calendar init           # Auto-detect ORM");
  log("  npx ethiopian-calendar init prisma    # Use Prisma");
  log("  npx ethiopian-calendar init drizzle   # Use Drizzle");
  log("");
}

function ensureDirectoryExists(filePath: string): void {
  const dir = path.dirname(filePath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function generatePrismaMigration(outputPath: string): void {
  const sql = getSql();
  ensureDirectoryExists(outputPath);
  fs.writeFileSync(outputPath, sql);
}

function generateDrizzleMigration(outputPath: string): void {
  const sql = getSql();
  ensureDirectoryExists(outputPath);
  fs.writeFileSync(outputPath, sql);
}

function generateTypeORMMigration(outputPath: string): void {
  const sql = getSql();
  const className = `EthiopianCalendar${Date.now()}`;

  const content = `import { MigrationInterface, QueryRunner } from "typeorm";

export class ${className} implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(\`
${sql.replace(/`/g, "\\`")}
    \`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Drop functions in reverse order
    await queryRunner.query(\`
      DROP FUNCTION IF EXISTS pg_ethiopian_to_datetime(timestamp);
      DROP FUNCTION IF EXISTS pg_ethiopian_to_timestamp(timestamp);
      DROP FUNCTION IF EXISTS pg_ethiopian_from_date(text);
      DROP FUNCTION IF EXISTS pg_ethiopian_to_date(timestamp);
      DROP FUNCTION IF EXISTS current_ethiopian_date();
      DROP FUNCTION IF EXISTS to_ethiopian_datetime(timestamp);
      DROP FUNCTION IF EXISTS to_ethiopian_timestamp(timestamp);
      DROP FUNCTION IF EXISTS from_ethiopian_date(text);
      DROP FUNCTION IF EXISTS to_ethiopian_date(timestamp);
      DROP FUNCTION IF EXISTS _ethiopian_to_jdn(integer, integer, integer);
      DROP FUNCTION IF EXISTS _jdn_to_ethiopian(integer);
      DROP FUNCTION IF EXISTS _jdn_to_gregorian(integer);
      DROP FUNCTION IF EXISTS _gregorian_to_jdn(integer, integer, integer);
    \`);
  }
}
`;

  ensureDirectoryExists(outputPath);
  fs.writeFileSync(outputPath, content);
}

function generateSequelizeMigration(outputPath: string): void {
  const sql = getSql();

  const content = `'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.sequelize.query(\`
${sql.replace(/`/g, "\\`")}
    \`);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.sequelize.query(\`
      DROP FUNCTION IF EXISTS pg_ethiopian_to_datetime(timestamp);
      DROP FUNCTION IF EXISTS pg_ethiopian_to_timestamp(timestamp);
      DROP FUNCTION IF EXISTS pg_ethiopian_from_date(text);
      DROP FUNCTION IF EXISTS pg_ethiopian_to_date(timestamp);
      DROP FUNCTION IF EXISTS current_ethiopian_date();
      DROP FUNCTION IF EXISTS to_ethiopian_datetime(timestamp);
      DROP FUNCTION IF EXISTS to_ethiopian_timestamp(timestamp);
      DROP FUNCTION IF EXISTS from_ethiopian_date(text);
      DROP FUNCTION IF EXISTS to_ethiopian_date(timestamp);
      DROP FUNCTION IF EXISTS _ethiopian_to_jdn(integer, integer, integer);
      DROP FUNCTION IF EXISTS _jdn_to_ethiopian(integer);
      DROP FUNCTION IF EXISTS _jdn_to_gregorian(integer);
      DROP FUNCTION IF EXISTS _gregorian_to_jdn(integer, integer, integer);
    \`);
  }
};
`;

  ensureDirectoryExists(outputPath);
  fs.writeFileSync(outputPath, content);
}

function generateKnexMigration(outputPath: string): void {
  const sql = getSql();

  const content = `/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.raw(\`
${sql.replace(/`/g, "\\`")}
  \`);
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.raw(\`
    DROP FUNCTION IF EXISTS pg_ethiopian_to_datetime(timestamp);
    DROP FUNCTION IF EXISTS pg_ethiopian_to_timestamp(timestamp);
    DROP FUNCTION IF EXISTS pg_ethiopian_from_date(text);
    DROP FUNCTION IF EXISTS pg_ethiopian_to_date(timestamp);
    DROP FUNCTION IF EXISTS current_ethiopian_date();
    DROP FUNCTION IF EXISTS to_ethiopian_datetime(timestamp);
    DROP FUNCTION IF EXISTS to_ethiopian_timestamp(timestamp);
    DROP FUNCTION IF EXISTS from_ethiopian_date(text);
    DROP FUNCTION IF EXISTS to_ethiopian_date(timestamp);
    DROP FUNCTION IF EXISTS _ethiopian_to_jdn(integer, integer, integer);
    DROP FUNCTION IF EXISTS _jdn_to_ethiopian(integer);
    DROP FUNCTION IF EXISTS _jdn_to_gregorian(integer);
    DROP FUNCTION IF EXISTS _gregorian_to_jdn(integer, integer, integer);
  \`);
};
`;

  ensureDirectoryExists(outputPath);
  fs.writeFileSync(outputPath, content);
}

function generateKyselyMigration(outputPath: string): void {
  const sql = getSql();

  const content = `import { Kysely, sql } from 'kysely';

export async function up(db: Kysely<any>): Promise<void> {
  await sql.raw(\`
${sql.replace(/`/g, "\\`")}
  \`).execute(db);
}

export async function down(db: Kysely<any>): Promise<void> {
  await sql.raw(\`
    DROP FUNCTION IF EXISTS pg_ethiopian_to_datetime(timestamp);
    DROP FUNCTION IF EXISTS pg_ethiopian_to_timestamp(timestamp);
    DROP FUNCTION IF EXISTS pg_ethiopian_from_date(text);
    DROP FUNCTION IF EXISTS pg_ethiopian_to_date(timestamp);
    DROP FUNCTION IF EXISTS current_ethiopian_date();
    DROP FUNCTION IF EXISTS to_ethiopian_datetime(timestamp);
    DROP FUNCTION IF EXISTS to_ethiopian_timestamp(timestamp);
    DROP FUNCTION IF EXISTS from_ethiopian_date(text);
    DROP FUNCTION IF EXISTS to_ethiopian_date(timestamp);
    DROP FUNCTION IF EXISTS _ethiopian_to_jdn(integer, integer, integer);
    DROP FUNCTION IF EXISTS _jdn_to_ethiopian(integer);
    DROP FUNCTION IF EXISTS _jdn_to_gregorian(integer);
    DROP FUNCTION IF EXISTS _gregorian_to_jdn(integer, integer, integer);
  \`).execute(db);
}
`;

  ensureDirectoryExists(outputPath);
  fs.writeFileSync(outputPath, content);
}

function generateMikroORMMigration(outputPath: string): void {
  const sql = getSql();
  const className = `EthiopianCalendar${Date.now()}`;

  const content = `import { Migration } from '@mikro-orm/migrations';

export class ${className} extends Migration {
  async up(): Promise<void> {
    this.addSql(\`
${sql.replace(/`/g, "\\`")}
    \`);
  }

  async down(): Promise<void> {
    this.addSql(\`
      DROP FUNCTION IF EXISTS pg_ethiopian_to_datetime(timestamp);
      DROP FUNCTION IF EXISTS pg_ethiopian_to_timestamp(timestamp);
      DROP FUNCTION IF EXISTS pg_ethiopian_from_date(text);
      DROP FUNCTION IF EXISTS pg_ethiopian_to_date(timestamp);
      DROP FUNCTION IF EXISTS current_ethiopian_date();
      DROP FUNCTION IF EXISTS to_ethiopian_datetime(timestamp);
      DROP FUNCTION IF EXISTS to_ethiopian_timestamp(timestamp);
      DROP FUNCTION IF EXISTS from_ethiopian_date(text);
      DROP FUNCTION IF EXISTS to_ethiopian_date(timestamp);
      DROP FUNCTION IF EXISTS _ethiopian_to_jdn(integer, integer, integer);
      DROP FUNCTION IF EXISTS _jdn_to_ethiopian(integer);
      DROP FUNCTION IF EXISTS _jdn_to_gregorian(integer);
      DROP FUNCTION IF EXISTS _gregorian_to_jdn(integer, integer, integer);
    \`);
  }
}
`;

  ensureDirectoryExists(outputPath);
  fs.writeFileSync(outputPath, content);
}

function generateRawMigration(outputPath: string): void {
  const sql = getSql();
  ensureDirectoryExists(outputPath);
  fs.writeFileSync(outputPath, sql);
}

function generateMigration(orm: SupportedORM, outputPath: string): void {
  switch (orm) {
    case "prisma":
      generatePrismaMigration(outputPath);
      break;
    case "drizzle":
      generateDrizzleMigration(outputPath);
      break;
    case "typeorm":
      generateTypeORMMigration(outputPath);
      break;
    case "sequelize":
      generateSequelizeMigration(outputPath);
      break;
    case "knex":
      generateKnexMigration(outputPath);
      break;
    case "kysely":
      generateKyselyMigration(outputPath);
      break;
    case "mikro-orm":
      generateMikroORMMigration(outputPath);
      break;
    case "raw":
    default:
      generateRawMigration(outputPath);
  }
}

function getNextSteps(orm: SupportedORM): string[] {
  switch (orm) {
    case "prisma":
      return [
        "Run: npx prisma migrate dev --name ethiopian_calendar",
        "Or if migration already created: npx prisma migrate deploy",
      ];
    case "drizzle":
      return [
        "Run: npx drizzle-kit migrate",
        "Or: npx drizzle-kit push",
      ];
    case "typeorm":
      return [
        "Run: npx typeorm migration:run",
      ];
    case "sequelize":
      return [
        "Run: npx sequelize-cli db:migrate",
      ];
    case "knex":
      return [
        "Run: npx knex migrate:latest",
      ];
    case "kysely":
      return [
        "Run your Kysely migration runner",
      ];
    case "mikro-orm":
      return [
        "Run: npx mikro-orm migration:up",
      ];
    case "raw":
    default:
      return [
        "Run: psql -d your_database -f ethiopian_calendar.sql",
        "Or use your preferred PostgreSQL client",
      ];
  }
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const command = args[0];

  printBanner();

  if (command === "help" || command === "--help" || command === "-h") {
    printUsage();
    process.exit(0);
  }

  if (command !== "init" && command !== undefined) {
    error(`Unknown command: ${command}`);
    log("");
    printUsage();
    process.exit(1);
  }

  // Get ORM from argument or auto-detect
  let orm: SupportedORM | null = args[1] as SupportedORM | undefined ?? null;

  if (!orm) {
    info("Auto-detecting ORM...");
    orm = detectOrm();

    if (!orm) {
      warn("Could not detect ORM. Using raw SQL output.");
      orm = "raw";
    } else {
      success(`Detected: ${orm}`);
    }
  } else {
    info(`Using specified ORM: ${orm}`);
  }

  // Generate migration
  const outputPath = getMigrationPath(orm);
  info(`Generating migration at: ${outputPath}`);

  try {
    generateMigration(orm, outputPath);
    success(`Created: ${outputPath}`);
  } catch (err) {
    error(`Failed to create migration: ${err}`);
    process.exit(1);
  }

  // Print next steps
  log("");
  log(`${colors.bright}Next steps:${colors.reset}`);
  const steps = getNextSteps(orm);
  steps.forEach((step, index) => {
    log(`  ${index + 1}. ${step}`);
  });

  log("");
  log(`${colors.bright}Available functions:${colors.reset}`);
  log("  • to_ethiopian_date(timestamp) → text");
  log("  • from_ethiopian_date(text) → timestamp");
  log("  • to_ethiopian_timestamp(timestamp) → timestamp");
  log("  • current_ethiopian_date() → text");
  log("");
  log(
    `${colors.cyan}Documentation: https://github.com/HuluWZ/pg-ethiopian-calendar${colors.reset}`
  );
  log("");
}

main().catch((err) => {
  error(`Unexpected error: ${err}`);
  process.exit(1);
});

