-- Ethiopian Calendar Functions for PostgreSQL
-- Version: 1.1.1

CREATE OR REPLACE FUNCTION _gregorian_to_jdn(g_year integer, g_month integer, g_day integer)
RETURNS integer LANGUAGE plpgsql IMMUTABLE STRICT AS $$
DECLARE a integer; y integer; m integer;
BEGIN
    a := (14 - g_month) / 12; y := g_year + 4800 - a; m := g_month + 12 * a - 3;
    RETURN g_day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045;
END; $$;

CREATE OR REPLACE FUNCTION _jdn_to_ethiopian(jdn integer)
RETURNS integer[] LANGUAGE plpgsql IMMUTABLE STRICT AS $$
DECLARE r integer; n integer; e_year integer; e_month integer; e_day integer;
BEGIN
    r := (jdn - 1723856) MOD 1461; n := (r MOD 365) + 365 * (r / 1460);
    e_year := 4 * ((jdn - 1723856) / 1461) + r / 365 - r / 1460;
    e_month := n / 30 + 1; e_day := (n MOD 30) + 1;
    RETURN ARRAY[e_year, e_month, e_day];
END; $$;

CREATE OR REPLACE FUNCTION _ethiopian_to_jdn(e_year integer, e_month integer, e_day integer)
RETURNS integer LANGUAGE plpgsql IMMUTABLE STRICT AS $$
DECLARE is_leap boolean; max_days integer;
BEGIN
    IF e_year < 1 THEN RAISE EXCEPTION 'Invalid Ethiopian year: %', e_year USING ERRCODE = 'datetime_field_overflow'; END IF;
    IF e_month < 1 OR e_month > 13 THEN RAISE EXCEPTION 'Invalid Ethiopian month: %', e_month USING ERRCODE = 'datetime_field_overflow'; END IF;
    IF e_day < 1 THEN RAISE EXCEPTION 'Invalid Ethiopian day: %', e_day USING ERRCODE = 'datetime_field_overflow'; END IF;
    IF e_month <= 12 AND e_day > 30 THEN RAISE EXCEPTION 'Invalid day % for month %', e_day, e_month USING ERRCODE = 'datetime_field_overflow'; END IF;
    IF e_month = 13 THEN
        is_leap := (e_year % 4 = 3); max_days := CASE WHEN is_leap THEN 6 ELSE 5 END;
        IF e_day > max_days THEN RAISE EXCEPTION 'Invalid day % for month 13', e_day USING ERRCODE = 'datetime_field_overflow'; END IF;
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
DECLARE parts text[]; e_year int; e_month int; e_day int; jdn int; a int; b int; c int; d int; e int; m int;
BEGIN
    parts := string_to_array(ethiopian_date, '-');
    IF array_length(parts, 1) != 3 THEN RAISE EXCEPTION 'Invalid format: %', ethiopian_date USING ERRCODE = 'invalid_datetime_format'; END IF;
    e_year := parts[1]::int; e_month := parts[2]::int; e_day := parts[3]::int;
    jdn := _ethiopian_to_jdn(e_year, e_month, e_day);
    a := jdn + 32044; b := (4 * a + 3) / 146097; c := a - (146097 * b / 4);
    d := (4 * c + 3) / 1461; e := c - (1461 * d / 4); m := (5 * e + 2) / 153;
    RETURN make_date(100 * b + d - 4800 + m / 10, m + 3 - 12 * (m / 10), e - (153 * m + 2) / 5 + 1);
END; $$;

CREATE OR REPLACE FUNCTION current_ethiopian_date() RETURNS text LANGUAGE sql STABLE AS $$ SELECT to_ethiopian_date(NOW()::timestamp); $$;
CREATE OR REPLACE FUNCTION ethiopian_calendar_version() RETURNS text LANGUAGE sql IMMUTABLE AS $$ SELECT '1.1.1'::text; $$;

-- Tables
CREATE TABLE "holidays" (
    "id" SERIAL PRIMARY KEY,
    "name" TEXT NOT NULL,
    "name_amharic" TEXT,
    "holiday_date" TIMESTAMP NOT NULL,
    "holiday_date_ethiopian" TIMESTAMP GENERATED ALWAYS AS (to_ethiopian_timestamp(holiday_date)) STORED,
    "type" TEXT NOT NULL DEFAULT 'national',
    "description" TEXT,
    "created_at" TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE "appointments" (
    "id" SERIAL PRIMARY KEY,
    "title" TEXT NOT NULL,
    "client_name" TEXT NOT NULL,
    "client_phone" TEXT,
    "appointment_time" TIMESTAMP NOT NULL,
    "appointment_time_ethiopian" TIMESTAMP GENERATED ALWAYS AS (to_ethiopian_timestamp(appointment_time)) STORED,
    "duration" INTEGER DEFAULT 60,
    "status" TEXT NOT NULL DEFAULT 'scheduled',
    "notes" TEXT,
    "created_at" TIMESTAMP DEFAULT NOW() NOT NULL,
    "created_at_ethiopian" TIMESTAMP GENERATED ALWAYS AS (to_ethiopian_timestamp(created_at)) STORED
);

CREATE TABLE "invoices" (
    "id" SERIAL PRIMARY KEY,
    "invoice_number" TEXT NOT NULL UNIQUE,
    "client_name" TEXT NOT NULL,
    "amount" DECIMAL(10,2) NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "due_date" TIMESTAMP NOT NULL,
    "due_date_ethiopian" TIMESTAMP GENERATED ALWAYS AS (to_ethiopian_timestamp(due_date)) STORED,
    "paid_at" TIMESTAMP,
    "paid_at_ethiopian" TIMESTAMP GENERATED ALWAYS AS (to_ethiopian_timestamp(paid_at)) STORED,
    "created_at" TIMESTAMP DEFAULT NOW() NOT NULL,
    "created_at_ethiopian" TIMESTAMP GENERATED ALWAYS AS (to_ethiopian_timestamp(created_at)) STORED
);

-- Notes table - Ethiopian timestamps ONLY (no Gregorian storage)
CREATE TABLE "notes" (
    "id" SERIAL PRIMARY KEY,
    "title" TEXT NOT NULL,
    "content" TEXT,
    "category" TEXT DEFAULT 'general',
    "created_at" TIMESTAMP NOT NULL DEFAULT to_ethiopian_timestamp()  -- Ethiopian timestamp only!
);

CREATE INDEX "idx_holidays_eth_date" ON "holidays" ("holiday_date_ethiopian");
CREATE INDEX "idx_appointments_time" ON "appointments" ("appointment_time");
CREATE INDEX "idx_appointments_eth_time" ON "appointments" ("appointment_time_ethiopian");
CREATE INDEX "idx_notes_created" ON "notes" ("created_at");

