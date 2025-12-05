#!/bin/bash
# Test runner script for pg_ethiopian_calendar extension
# Waits for PostgreSQL, installs extensions, and runs pgTAP tests

set -e

# Configuration
PGUSER="${POSTGRES_USER:-testuser}"
PGPASSWORD="${POSTGRES_PASSWORD:-testpass}"
PGDB="${POSTGRES_DB:-testdb}"
PGHOST="${POSTGRES_HOST:-localhost}"
PGPORT="${POSTGRES_PORT:-5432}"

# Export for psql
export PGHOST PGPORT PGUSER PGDATABASE="$PGDB"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Waiting for PostgreSQL to be ready...${NC}"

# Wait for PostgreSQL to be ready
for i in {1..30}; do
    if pg_isready -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" > /dev/null 2>&1; then
        echo -e "${GREEN}PostgreSQL is ready!${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}PostgreSQL failed to start after 30 attempts${NC}"
        exit 1
    fi
    sleep 1
done

# Additional wait to ensure PostgreSQL is fully ready
sleep 2

echo -e "${YELLOW}Creating test database if it doesn't exist...${NC}"
# Create database if it doesn't exist (ignore error if it does)
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d postgres -c "CREATE DATABASE $PGDB;" 2>/dev/null || true

echo -e "${YELLOW}Installing pgTAP extension...${NC}"
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDB" <<EOF
-- Try to create pgTAP extension
-- If pgTAP is not available, we'll install it manually
DO \$\$
BEGIN
    CREATE EXTENSION IF NOT EXISTS pgtap;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'pgTAP extension not found, attempting manual installation...';
END
\$\$;
EOF

# Check if pgTAP functions are available
PGTAP_AVAILABLE=$(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDB" -t -c "SELECT COUNT(*) FROM pg_proc WHERE proname = 'plan';" | tr -d ' ')

if [ "$PGTAP_AVAILABLE" = "0" ]; then
    echo -e "${YELLOW}pgTAP not found in database. Installing from source...${NC}"
    # Try to install pgTAP manually if extension creation failed
    # This is a fallback - in production, pgTAP should be installed via the Dockerfile
    echo -e "${RED}Warning: pgTAP is not available. Tests may fail.${NC}"
    echo -e "${YELLOW}Please ensure pgTAP is installed in the Dockerfile.${NC}"
fi

echo -e "${YELLOW}Installing pg_ethiopian_calendar extension...${NC}"

# Install the extension (make install)
cd /usr/src/extension
make install

# Create the extension in the database
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDB" <<EOF
-- Drop extension if it exists (for clean testing)
DROP EXTENSION IF EXISTS pg_ethiopian_calendar CASCADE;

-- Create the extension
CREATE EXTENSION pg_ethiopian_calendar;

-- Verify extension is installed
SELECT extname, extversion FROM pg_extension WHERE extname = 'pg_ethiopian_calendar';
EOF

echo -e "${YELLOW}Running pgTAP tests...${NC}"

# Check if pg_prove is available
if command -v pg_prove &> /dev/null; then
    # Run tests using pg_prove
    cd /usr/src/extension
    pg_prove -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDB" test/tests/ethiopian_calendar_tests.sql
    TEST_EXIT_CODE=$?
else
    # Fallback: run tests directly with psql
    echo -e "${YELLOW}pg_prove not found, running tests with psql...${NC}"
    cd /usr/src/extension
    psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDB" -f test/tests/ethiopian_calendar_tests.sql
    TEST_EXIT_CODE=$?
fi

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Tests failed with exit code $TEST_EXIT_CODE${NC}"
    exit $TEST_EXIT_CODE
fi

