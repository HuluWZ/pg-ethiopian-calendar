# Ethiopian Calendar Extension for PostgreSQL

A PostgreSQL extension that converts Gregorian timestamps to Ethiopian calendar dates using academically verified formulas from "Calendrical Calculations" by Nachum Dershowitz & Edward M. Reingold (Cambridge University Press).

## Overview

The Ethiopian calendar is a solar calendar with 13 months:
- 12 months of 30 days each (Meskerem, Tikimt, Hidar, Tahsas, Tir, Yekatit, Megabit, Miazia, Ginbot, Sene, Hamle, Nehase)
- 1 month of 5 or 6 days (Pagumē, month 13)
- Leap years occur every 4 years (years where `year % 4 == 3`), adding a 6th day to Pagumē
- The Ethiopian New Year (Meskerem 1) typically falls on September 11 or 12 in the Gregorian calendar
- The Ethiopian calendar is approximately 7-8 years behind the Gregorian calendar

## Quick Start with Docker (Recommended)

The easiest way to get started is using Docker. No need to install PostgreSQL development headers or build tools!

### Using Makefile Commands (Recommended)

All operations are handled through Docker Compose via Makefile targets:

```bash
# Start PostgreSQL with the extension pre-installed (production mode)
make docker-start

# Or start in development mode (mounts source code)
make docker-dev

# Connect to database and create extension
make docker-shell
# Then in psql: CREATE EXTENSION pg_ethiopian_calendar;

# Run tests
make docker-test

# View logs
make docker-logs

# Show status
make docker-status

# Stop containers
make docker-stop

# Clean up everything
make docker-clean

# See all available commands
make docker-help
```

### Using Docker Compose Directly

You can also use `docker compose` commands directly:

```bash
# Start PostgreSQL (production)
docker compose --profile default up -d postgres

# Start PostgreSQL (development)
docker compose --profile dev up -d postgres-dev

# Run tests
docker compose --profile test up --build --abort-on-container-exit test

# Connect to PostgreSQL
docker compose exec postgres psql -U postgres

# Or from your host machine (if you have psql installed)
psql -h localhost -U postgres -d postgres
# Password: postgres (or from .env file)
```

### Quick Test

Once PostgreSQL is running:

```bash
# Connect to database
make docker-shell

# In psql, create the extension and test:
CREATE EXTENSION pg_ethiopian_calendar;
SELECT to_ethiopian_date(NOW());

# Or one-liner:
docker compose exec postgres psql -U postgres -c "CREATE EXTENSION IF NOT EXISTS pg_ethiopian_calendar; SELECT to_ethiopian_date(NOW());"
```

### Configuration with .env File

**The `.env` file is REQUIRED.** The Docker setup uses environment variables for configuration. You must create a `.env` file:

```bash
# Create .env from the example template (REQUIRED)
cp .env.example .env

# Edit .env and set your required values
nano .env  # or use your preferred editor
```

**Important:** All environment variables must be set. The `make docker-init` command will automatically create `.env` from `.env.example` if it doesn't exist, but you should review and customize the values.

The `.env` file is **required** and must contain:

- **PostgreSQL credentials**: `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` (required)
- **Port mapping**: `POSTGRES_PORT` (required)
- **PostgreSQL version**: `PG_VERSION` (required, e.g., 14, 15, 16)
- **Test database settings**: `TEST_POSTGRES_*` variables (required for testing)

**Example `.env` file:**

```bash
# PostgreSQL Configuration (REQUIRED)
POSTGRES_USER=myuser
POSTGRES_PASSWORD=mysecurepassword
POSTGRES_DB=myapp
POSTGRES_PORT=5432
PG_VERSION=14

# Test Database Configuration (REQUIRED for testing)
TEST_POSTGRES_USER=testuser
TEST_POSTGRES_PASSWORD=testpass
TEST_POSTGRES_DB=testdb
TEST_POSTGRES_PORT=5433
```

**Note:** The `.env` file is automatically ignored by git (in `.gitignore`) to keep your credentials secure. You must create a `.env` file from `.env.example` before running any docker commands.

## Installation (Manual)

### Prerequisites

- PostgreSQL 11 or later
- PostgreSQL development headers (`postgresql-server-dev-*` on Debian/Ubuntu, `postgresql-devel` on RHEL/CentOS)
- `make` and a C compiler (gcc)

### Build and Install

```bash
# Build the extension
make

# Install the extension (requires superuser privileges)
sudo make install

# Create the extension in your database
psql -d your_database -c "CREATE EXTENSION pg_ethiopian_calendar;"
```

## Functions

### Primary Functions

#### `to_ethiopian_date(timestamp) → text` / `pg_ethiopian_to_date(timestamp) → text`

Converts a Gregorian timestamp to an Ethiopian calendar date as text. The time component is discarded; only the date is converted.

**Parameters:**
- `timestamp`: A Gregorian calendar timestamp

**Returns:**
- `text`: Ethiopian calendar date as string in format "YYYY-MM-DD"

**Examples:**
```sql
-- Using original name
SELECT to_ethiopian_date('2024-01-01'::timestamp);
-- Returns: '2016-04-23'

-- Using pg_ prefixed alias (PostgreSQL extension naming convention)
SELECT pg_ethiopian_to_date('2024-01-01'::timestamp);
-- Returns: '2016-04-23'
```

#### `from_ethiopian_date(text) → timestamp` / `pg_ethiopian_from_date(text) → timestamp`

Converts an Ethiopian calendar date string to a Gregorian timestamp. The input should be in format "YYYY-MM-DD" (Ethiopian calendar).

**Parameters:**
- `ethiopian_date`: Ethiopian calendar date as text (format: YYYY-MM-DD)

**Returns:**
- `timestamp`: Gregorian calendar timestamp at midnight

**Examples:**
```sql
-- Using original name
SELECT from_ethiopian_date('2016-04-23');
-- Returns: '2024-01-01 00:00:00'::timestamp

-- Using pg_ prefixed alias
SELECT pg_ethiopian_from_date('2016-04-23');
-- Returns: '2024-01-01 00:00:00'::timestamp
```

#### `to_ethiopian_datetime(timestamp) → timestamp with time zone` / `pg_ethiopian_to_datetime(timestamp) → timestamp with time zone`

Converts a Gregorian timestamp to an Ethiopian calendar TIMESTAMP WITH TIME ZONE. The date is converted to Ethiopian calendar; the time-of-day remains the same.

**Parameters:**
- `timestamp`: A Gregorian calendar timestamp

**Returns:**
- `timestamp with time zone`: A timestamp with the date in Ethiopian calendar and the original time preserved

**Examples:**
```sql
-- Using original name
SELECT to_ethiopian_datetime('2024-01-01 14:30:00'::timestamp);

-- Using pg_ prefixed alias
SELECT pg_ethiopian_to_datetime('2024-01-01 14:30:00'::timestamp);
```

#### `to_ethiopian_timestamp(timestamp) → timestamp` / `pg_ethiopian_to_timestamp(timestamp) → timestamp`

Converts a Gregorian timestamp to an Ethiopian calendar TIMESTAMP (without time zone). The date is converted to Ethiopian calendar; the time-of-day remains the same. **This function is ideal for use in generated columns** where you want a `TIMESTAMP` type (not `TEXT`).

**Parameters:**
- `timestamp`: A Gregorian calendar timestamp

**Returns:**
- `timestamp`: A timestamp (without time zone) with the date in Ethiopian calendar and the original time preserved

**Examples:**
```sql
-- Using original name
SELECT to_ethiopian_timestamp('2024-01-01 14:30:00'::timestamp);

-- Using pg_ prefixed alias
SELECT pg_ethiopian_to_timestamp('2024-01-01 14:30:00'::timestamp);

-- In generated columns
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT NOW(),
    created_at_ethiopian TIMESTAMP GENERATED ALWAYS AS (to_ethiopian_timestamp(created_at)) STORED
);
```

#### `current_ethiopian_date() → text`

Returns the current date in Ethiopian calendar as text. This function is `STABLE` (not `IMMUTABLE`) because it depends on the current time. Useful for `DEFAULT` values.

**Returns:**
- `text`: Current Ethiopian calendar date as string in format "YYYY-MM-DD"

**Examples:**
```sql
-- Get current Ethiopian date
SELECT current_ethiopian_date();

-- Use as default value
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    event_date_ethiopian TEXT DEFAULT current_ethiopian_date()
);
```

### Function Naming

The extension provides both naming styles:
- **Original names**: `to_ethiopian_date()`, `from_ethiopian_date()`, `to_ethiopian_datetime()`, `to_ethiopian_timestamp()`, `current_ethiopian_date()`
- **pg_ prefixed aliases**: `pg_ethiopian_to_date()`, `pg_ethiopian_from_date()`, `pg_ethiopian_to_datetime()`, `pg_ethiopian_to_timestamp()`

Both styles are equivalent and call the same underlying C functions. Use whichever style you prefer. The `pg_` prefixed versions follow PostgreSQL extension naming conventions (similar to `pg_stat_statements`, `pg_trgm`).

## Usage Examples

### Basic Conversion

```sql
-- Convert Gregorian to Ethiopian
SELECT to_ethiopian_date('2024-01-01'::timestamp);
-- Returns: '2016-04-23'

-- Convert current timestamp
SELECT to_ethiopian_date(NOW()::timestamp);

-- Reverse conversion: Ethiopian to Gregorian
SELECT from_ethiopian_date('2016-04-23');
-- Returns: '2024-01-01 00:00:00'::timestamp

-- Convert with time preserved
SELECT to_ethiopian_datetime('2024-12-25 23:59:59'::timestamp);

-- Round-trip conversion
SELECT from_ethiopian_date(to_ethiopian_date('2024-01-01'::timestamp));
-- Returns: '2024-01-01 00:00:00'::timestamp
```

### Generated Columns

You can use these functions in generated columns to automatically maintain Ethiopian calendar dates. You have two options:

**Option 1: Using TIMESTAMP type (Recommended for timestamps)**
```sql
CREATE TABLE sample (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT NOW(),
    created_at_ethiopian TIMESTAMP GENERATED ALWAYS AS (to_ethiopian_timestamp(created_at)) STORED,
    updated_at TIMESTAMP DEFAULT NOW(),
    updated_at_ethiopian TIMESTAMP GENERATED ALWAYS AS (to_ethiopian_timestamp(updated_at)) STORED
);

INSERT INTO sample (created_at) VALUES (NOW());
SELECT * FROM sample;
```

**Option 2: Using TEXT type (For date-only values)**
```sql
CREATE TABLE sample (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT NOW(),
    created_at_et TEXT GENERATED ALWAYS AS (to_ethiopian_date(created_at)) STORED
);

INSERT INTO sample (created_at) VALUES (NOW());
SELECT * FROM sample;
```

**Option 3: Using DEFAULT with current_ethiopian_date()**
```sql
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    event_date_ethiopian TEXT DEFAULT current_ethiopian_date()
);
```

### Querying with Ethiopian Dates

```sql
-- Find records created on a specific Ethiopian date
SELECT *
FROM sample
WHERE created_at_et = to_ethiopian_date('2024-01-15'::timestamp);

-- Convert multiple dates
SELECT 
    created_at,
    to_ethiopian_date(created_at) AS ethiopian_date
FROM sample;
```

## Implementation Details

### Conversion Algorithm

The extension uses Julian Day Number (JDN) as an intermediate representation for calendar conversions:

1. **Gregorian → JDN**: Convert the input Gregorian date to Julian Day Number using the standard formula from "Calendrical Calculations"
2. **JDN → Ethiopian**: Convert the JDN to Ethiopian calendar date components (year, month, day)
3. **Ethiopian → JDN → Gregorian**: Convert back to Gregorian DATE for PostgreSQL storage (since PostgreSQL DATE is always Gregorian internally)

The conversion formulas are based on:
- **Ethiopian Epoch**: August 29, 8 CE (Gregorian) = JDN 1724221
- **4-year cycles**: The Ethiopian calendar uses 4-year eras (1461 days total: 3 years of 365 days + 1 leap year of 366 days)
- **Leap years**: Years where `year % 4 == 3` are leap years

### Technical Notes

- **DATE Type Limitation**: PostgreSQL's `DATE` type is always stored as Gregorian internally. The functions perform the conversion and return a DATE value that represents the same calendar day (same JDN) in the Ethiopian calendar system.
- **Time Preservation**: `to_ethiopian_datetime()` preserves the original time-of-day while converting only the date portion.
- **NULL Handling**: Both functions return NULL if the input timestamp is NULL.
- **Immutability**: Both functions are marked as `IMMUTABLE` and `STRICT` for optimal query planning and NULL handling.

## Quick Testing Guide

### Quick Start Testing

```bash
# 1. Start PostgreSQL container
make docker-start

# 2. Connect to database
make docker-shell

# 3. In psql, create extension and test
CREATE EXTENSION pg_ethiopian_calendar;
SELECT to_ethiopian_date('2024-01-01'::timestamp);
SELECT pg_ethiopian_to_date('2024-01-01'::timestamp);
SELECT from_ethiopian_date('2016-04-23');
```

### Quick Command-Line Test

```bash
# Test functions without interactive psql
docker compose exec -T postgres psql -U postgres -c \
  "CREATE EXTENSION IF NOT EXISTS pg_ethiopian_calendar; \
   SELECT to_ethiopian_date('2024-01-01'::timestamp) AS ethiopian_date;"
```

For detailed testing, use `make docker-test`.

## Testing

The extension includes comprehensive pgTAP unit tests and a Docker-based test environment.

### Running Tests with Docker (Recommended)

The easiest way to run tests is using Makefile:

```bash
# Run all tests
make docker-test

# Or use docker compose directly
docker compose --profile test up --build --abort-on-container-exit test
```

This will:
1. Build a PostgreSQL container (default: version 14, supports 11+) with pgTAP installed
2. Build and install the extension
3. Run all pgTAP tests automatically
4. Exit with the test results

### Running Tests from test/ Directory

You can also run tests from the test directory:

```bash
cd test
docker compose up --build --abort-on-container-exit
```

### Test Coverage

The test suite (`test/tests/ethiopian_calendar_tests.sql`) includes:

- Extension loading and function existence checks
- Type verification for return values
- Known reference conversions
- NULL input handling
- Time component preservation/discarding
- Consistency checks
- Leap year boundary tests (both Gregorian and Ethiopian)
- Year boundary tests
- Function immutability and strictness verification

### Manual Testing

To run tests manually:

```bash
# Install pgTAP in your PostgreSQL database
CREATE EXTENSION pgtap;

# Create the extension
CREATE EXTENSION pg_ethiopian_calendar;

# Run tests
psql -d your_database -f test/tests/ethiopian_calendar_tests.sql
```

## Project Structure

```
pg-ethiopian-calendar/
├── Makefile                    # Build configuration using PGXS
├── pg_ethiopian_calendar.control  # Extension metadata
├── META.json                   # PGXN metadata
├── README.md                   # This file
├── LICENSE                     # PostgreSQL License
├── .gitignore                  # Git ignore patterns
├── .dockerignore               # Docker ignore patterns
├── .env.example                # Environment variables template
├── Dockerfile                  # Production Docker image
├── Dockerfile.dev              # Development Docker image
├── docker-compose.yml          # Docker Compose configuration
├── src/
│   └── ethiopian_calendar.c   # C implementation
├── sql/
│   └── pg_ethiopian_calendar--1.0.sql  # SQL function definitions
└── test/
    ├── Dockerfile              # Docker image for testing
    ├── docker-compose.yml      # Docker Compose configuration for tests
    ├── pgtest.sh               # Test runner script
    └── tests/
        └── ethiopian_calendar_tests.sql  # pgTAP test suite
```

## References

- Dershowitz, Nachum & Reingold, Edward M. (2008). *Calendrical Calculations* (3rd ed.). Cambridge University Press. [ISBN: 978-0-521-88540-9](https://www.cambridge.org/core/books/calendrical-calculations/B897CA3260110348F1F7D906B8D9480D)
- PostgreSQL Extension Building: https://www.postgresql.org/docs/current/extend-pgxs.html

## License

This extension is provided as-is for educational and practical use.

## Extension Standards

This extension follows PostgreSQL extension standards:

- ✅ **PGXS-based build system** - Uses PostgreSQL Extension System
- ✅ **Versioned SQL migrations** - Follows `extension--version.sql` naming
- ✅ **Standard control file** - Proper metadata and configuration
- ✅ **Proper function attributes** - `IMMUTABLE STRICT` for optimal performance
- ✅ **Error handling** - Uses PostgreSQL `ereport` for errors
- ✅ **Documentation** - Functions documented with `COMMENT`
- ✅ **Naming conventions** - Lowercase with underscores, descriptive names

See `EXTENSION_STANDARDS.md` and `NAMING_CONVENTIONS.md` for detailed information.

## Contributing

Contributions, bug reports, and feature requests are welcome! 

Key points:
- Maintain compatibility with PostgreSQL 11+
- Follow the conversion formulas from "Calendrical Calculations"
- Include tests for new features
- Update documentation as needed

Submit issues and pull requests at: https://github.com/HuluWZ/pg-ethiopian-calendar

## PostgreSQL Version Support

The extension supports **PostgreSQL 11 and later**. 

### Using Different PostgreSQL Versions with Docker

You can specify the PostgreSQL version using the `PG_VERSION` environment variable:

```bash
# Use PostgreSQL 11
PG_VERSION=11 make docker-start

# Use PostgreSQL 12
PG_VERSION=12 make docker-start

# Use PostgreSQL 13
PG_VERSION=13 make docker-start

# Use PostgreSQL 14 (default)
make docker-start

# Use PostgreSQL 15
PG_VERSION=15 make docker-start

# Use PostgreSQL 16
PG_VERSION=16 make docker-start
```

Or with docker compose directly:

```bash
PG_VERSION=11 docker compose build postgres
PG_VERSION=11 docker compose up -d postgres
```

## License

This extension is released under the PostgreSQL License. See [LICENSE](LICENSE) for details.

