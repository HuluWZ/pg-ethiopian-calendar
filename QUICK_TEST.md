# Quick Test Reference

## 🚀 Start & Connect (3 Commands)

```bash
# 1. Start container
make docker-start

# 2. Connect to database
make docker-shell

# 3. In psql, create extension
CREATE EXTENSION pg_ethiopian_calendar;
```

## ✅ Test with Your Own Dates

### Convert Your Date to Ethiopian

```sql
-- Replace '2024-12-25' with your own date
SELECT to_ethiopian_date('2024-12-25'::timestamp) AS ethiopian_date;

-- Or use pg_ prefixed function
SELECT pg_ethiopian_to_date('2024-12-25'::timestamp) AS ethiopian_date;
```

### Convert Ethiopian Date to Gregorian

```sql
-- Replace '2016-08-15' with your Ethiopian date (format: YYYY-MM-DD)
SELECT from_ethiopian_date('2016-08-15') AS gregorian_date;

-- Or use pg_ prefixed function
SELECT pg_ethiopian_from_date('2016-08-15') AS gregorian_date;
```

### Round-Trip Test

```sql
-- Test that conversion works both ways
SELECT 
    '2024-12-25'::timestamp AS original,
    to_ethiopian_date('2024-12-25'::timestamp) AS to_ethiopian,
    from_ethiopian_date(to_ethiopian_date('2024-12-25'::timestamp)) AS back_to_gregorian;
```

## 📋 Basic Function Tests (Examples)

```sql
-- Test 1: Convert Gregorian → Ethiopian
SELECT to_ethiopian_date('2024-01-01'::timestamp);
-- Result: 2016-04-23

-- Test 2: Convert Ethiopian → Gregorian
SELECT from_ethiopian_date('2016-04-23');
-- Result: 2024-01-01 00:00:00

-- Test 3: Using pg_ prefixed functions
SELECT pg_ethiopian_to_date('2024-01-01'::timestamp);
SELECT pg_ethiopian_from_date('2016-04-23');
```

## 🔍 Verify Installation

```sql
-- Check extension version
SELECT extname, extversion FROM pg_extension WHERE extname = 'pg_ethiopian_calendar';

-- List all functions
SELECT proname FROM pg_proc WHERE proname LIKE '%ethiopian%' ORDER BY proname;
```

## 📋 One-Line Test (Command Line)

```bash
docker compose exec -T postgres psql -U postgres -c \
  "CREATE EXTENSION IF NOT EXISTS pg_ethiopian_calendar; \
   SELECT to_ethiopian_date('2024-01-01'::timestamp);"
```

## 🧪 Run Automated Tests

```bash
make docker-test
```

## 📚 More Details

- **Testing with your own dates**: `QUICK_START.md` ⭐
- Full testing guide: `TESTING.md`
- Function documentation: `README.md`
- Docker guide: `DOCKER.md`

