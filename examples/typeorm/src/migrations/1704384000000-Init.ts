import { MigrationInterface, QueryRunner } from "typeorm";

export class Init1704384000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // Ethiopian Calendar Functions
    await queryRunner.query(`
      CREATE OR REPLACE FUNCTION _gregorian_to_jdn(g_year integer, g_month integer, g_day integer)
      RETURNS integer LANGUAGE plpgsql IMMUTABLE STRICT AS $$
      DECLARE a integer; y integer; m integer;
      BEGIN
          a := (14 - g_month) / 12; y := g_year + 4800 - a; m := g_month + 12 * a - 3;
          RETURN g_day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045;
      END; $$;

      CREATE OR REPLACE FUNCTION _jdn_to_ethiopian(jdn integer)
      RETURNS integer[] LANGUAGE plpgsql IMMUTABLE STRICT AS $$
      DECLARE r integer; n integer;
      BEGIN
          r := (jdn - 1723856) MOD 1461;
          n := (r MOD 365) + 365 * (r / 1460);
          RETURN ARRAY[
            4 * ((jdn - 1723856) / 1461) + r / 365 - r / 1460,
            n / 30 + 1,
            (n MOD 30) + 1
          ];
      END; $$;

      CREATE OR REPLACE FUNCTION _ethiopian_to_jdn(e_year integer, e_month integer, e_day integer)
      RETURNS integer LANGUAGE plpgsql IMMUTABLE STRICT AS $$
      BEGIN
          IF e_year < 1 THEN RAISE EXCEPTION 'Invalid year: %', e_year; END IF;
          IF e_month < 1 OR e_month > 13 THEN RAISE EXCEPTION 'Invalid month: %', e_month; END IF;
          IF e_day < 1 OR (e_month <= 12 AND e_day > 30) THEN RAISE EXCEPTION 'Invalid day: %', e_day; END IF;
          IF e_month = 13 AND e_day > CASE WHEN e_year % 4 = 3 THEN 6 ELSE 5 END THEN
              RAISE EXCEPTION 'Invalid day: % for month 13', e_day;
          END IF;
          RETURN 1723856 + 365 * e_year + e_year / 4 + 30 * (e_month - 1) + e_day - 1;
      END; $$;

      CREATE OR REPLACE FUNCTION to_ethiopian_date(ts timestamp) RETURNS text LANGUAGE plpgsql IMMUTABLE STRICT AS $$
      DECLARE jdn integer; eth integer[];
      BEGIN
          jdn := _gregorian_to_jdn(EXTRACT(YEAR FROM ts)::int, EXTRACT(MONTH FROM ts)::int, EXTRACT(DAY FROM ts)::int);
          eth := _jdn_to_ethiopian(jdn);
          RETURN eth[1] || '-' || LPAD(eth[2]::text, 2, '0') || '-' || LPAD(eth[3]::text, 2, '0');
      END; $$;

      CREATE OR REPLACE FUNCTION to_ethiopian_date() RETURNS text LANGUAGE sql STABLE AS $$ SELECT to_ethiopian_date(NOW()::timestamp); $$;

      CREATE OR REPLACE FUNCTION to_ethiopian_timestamp(ts timestamp) RETURNS timestamp LANGUAGE plpgsql IMMUTABLE STRICT AS $$
      DECLARE jdn integer; eth integer[];
      BEGIN
          jdn := _gregorian_to_jdn(EXTRACT(YEAR FROM ts)::int, EXTRACT(MONTH FROM ts)::int, EXTRACT(DAY FROM ts)::int);
          eth := _jdn_to_ethiopian(jdn);
          RETURN (eth[1] || '-' || LPAD(eth[2]::text, 2, '0') || '-' || LPAD(eth[3]::text, 2, '0') || ' ' || TO_CHAR(ts, 'HH24:MI:SS.US'))::timestamp;
      END; $$;

      CREATE OR REPLACE FUNCTION to_ethiopian_timestamp() RETURNS timestamp LANGUAGE sql STABLE AS $$ SELECT to_ethiopian_timestamp(NOW()::timestamp); $$;

      CREATE OR REPLACE FUNCTION from_ethiopian_date(ethiopian_date text) RETURNS date LANGUAGE plpgsql IMMUTABLE STRICT AS $$
      DECLARE parts text[]; jdn int; a int; b int; c int; d int; e int; m int;
      BEGIN
          parts := string_to_array(ethiopian_date, '-');
          IF array_length(parts, 1) != 3 THEN RAISE EXCEPTION 'Invalid format: %', ethiopian_date; END IF;
          jdn := _ethiopian_to_jdn(parts[1]::int, parts[2]::int, parts[3]::int);
          a := jdn + 32044; b := (4 * a + 3) / 146097; c := a - (146097 * b / 4);
          d := (4 * c + 3) / 1461; e := c - (1461 * d / 4); m := (5 * e + 2) / 153;
          RETURN make_date(100 * b + d - 4800 + m / 10, m + 3 - 12 * (m / 10), e - (153 * m + 2) / 5 + 1);
      END; $$;

      CREATE OR REPLACE FUNCTION current_ethiopian_date() RETURNS text LANGUAGE sql STABLE AS $$ SELECT to_ethiopian_date(NOW()::timestamp); $$;
      CREATE OR REPLACE FUNCTION ethiopian_calendar_version() RETURNS text LANGUAGE sql IMMUTABLE AS $$ SELECT '1.1.1'::text; $$;
    `);

    // Tables
    await queryRunner.query(`
      CREATE TABLE "authors" (
        "id" SERIAL PRIMARY KEY,
        "name" VARCHAR NOT NULL,
        "email" VARCHAR NOT NULL UNIQUE,
        "bio" TEXT,
        "created_at" TIMESTAMP DEFAULT NOW() NOT NULL,
        "created_at_ethiopian" TIMESTAMP GENERATED ALWAYS AS (to_ethiopian_timestamp(created_at)) STORED
      );

      CREATE TABLE "posts" (
        "id" SERIAL PRIMARY KEY,
        "title" VARCHAR NOT NULL,
        "content" TEXT NOT NULL,
        "status" VARCHAR DEFAULT 'draft' NOT NULL,
        "author_id" INTEGER NOT NULL REFERENCES "authors"("id"),
        "published_at" TIMESTAMP,
        "published_at_ethiopian" TIMESTAMP GENERATED ALWAYS AS (to_ethiopian_timestamp(published_at)) STORED,
        "created_at" TIMESTAMP DEFAULT NOW() NOT NULL,
        "created_at_ethiopian" TIMESTAMP GENERATED ALWAYS AS (to_ethiopian_timestamp(created_at)) STORED,
        "updated_at" TIMESTAMP DEFAULT NOW() NOT NULL,
        "updated_at_ethiopian" TIMESTAMP GENERATED ALWAYS AS (to_ethiopian_timestamp(updated_at)) STORED
      );

      CREATE TABLE "comments" (
        "id" SERIAL PRIMARY KEY,
        "author_name" VARCHAR NOT NULL,
        "content" TEXT NOT NULL,
        "post_id" INTEGER NOT NULL REFERENCES "posts"("id") ON DELETE CASCADE,
        "created_at" TIMESTAMP DEFAULT NOW() NOT NULL,
        "created_at_ethiopian" TIMESTAMP GENERATED ALWAYS AS (to_ethiopian_timestamp(created_at)) STORED
      );

      CREATE INDEX "idx_posts_published_ethiopian" ON "posts"("published_at_ethiopian");
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "comments"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "posts"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "authors"`);
    await queryRunner.query(`DROP FUNCTION IF EXISTS ethiopian_calendar_version()`);
    await queryRunner.query(`DROP FUNCTION IF EXISTS current_ethiopian_date()`);
    await queryRunner.query(`DROP FUNCTION IF EXISTS from_ethiopian_date(text)`);
    await queryRunner.query(`DROP FUNCTION IF EXISTS to_ethiopian_timestamp()`);
    await queryRunner.query(`DROP FUNCTION IF EXISTS to_ethiopian_timestamp(timestamp)`);
    await queryRunner.query(`DROP FUNCTION IF EXISTS to_ethiopian_date()`);
    await queryRunner.query(`DROP FUNCTION IF EXISTS to_ethiopian_date(timestamp)`);
    await queryRunner.query(`DROP FUNCTION IF EXISTS _ethiopian_to_jdn(integer, integer, integer)`);
    await queryRunner.query(`DROP FUNCTION IF EXISTS _jdn_to_ethiopian(integer)`);
    await queryRunner.query(`DROP FUNCTION IF EXISTS _gregorian_to_jdn(integer, integer, integer)`);
  }
}

