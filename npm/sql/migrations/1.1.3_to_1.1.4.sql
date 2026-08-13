-- Ethiopian Calendar Upgrade: 1.1.3 → 1.1.4
-- Fixes: incorrect Ethiopian leap-year rule (was year % 4 == 3, now year % 4 == 0)
--
-- This corrects a bug where Pagumē 6 (the 6th epagomenal day) was silently
-- clamped to Pagumē 5 in true leap years, and from_ethiopian_date() rejected
-- valid Pagumē 6 dates in leap years while silently accepting/mis-converting
-- Pagumē 6 in non-leap years instead of raising an error.

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'ethiopian_calendar_version') THEN
        RAISE NOTICE 'Current version: %', ethiopian_calendar_version();
    ELSE
        RAISE NOTICE 'No version function found - assuming pre-1.1.0';
    END IF;
END;
$$;

-- Bump version string (was '1.1.3', now '1.1.4')
CREATE OR REPLACE FUNCTION ethiopian_calendar_version()
RETURNS text LANGUAGE sql IMMUTABLE AS $$ SELECT '1.1.4'::text; $$;

-- Fix _jdn_to_ethiopian: correct leap-year check when bounding Pagumē (month 13)
CREATE OR REPLACE FUNCTION _jdn_to_ethiopian(jdn integer)
RETURNS TABLE(e_year integer, e_month integer, e_day integer)
LANGUAGE plpgsql
IMMUTABLE STRICT
AS $$
DECLARE
    ethiopian_epoch constant integer := 1724221;
    days_since_epoch integer;
    era integer;
    year_of_era integer;
    day_of_year integer;
    is_leap boolean;
    max_days integer;
BEGIN
    IF jdn < ethiopian_epoch THEN
        RAISE EXCEPTION 'Julian Day Number % is before Ethiopian calendar epoch (JDN %)', jdn, ethiopian_epoch
            USING ERRCODE = 'datetime_field_overflow';
    END IF;

    days_since_epoch := jdn - ethiopian_epoch;
    era := days_since_epoch / 1461;
    year_of_era := (days_since_epoch % 1461) / 365;
    day_of_year := (days_since_epoch % 1461) % 365;

    IF year_of_era = 4 THEN
        year_of_era := 3;
        day_of_year := 365;
    END IF;

    e_year := 4 * era + year_of_era + 1;

    IF day_of_year < 360 THEN
        e_month := day_of_year / 30 + 1;
        e_day := (day_of_year % 30) + 1;
    ELSE
        e_month := 13;
        e_day := day_of_year - 360 + 1;
        is_leap := (e_year % 4 = 0);
        max_days := CASE WHEN is_leap THEN 6 ELSE 5 END;
        IF e_day > max_days THEN
            e_day := max_days;
        END IF;
    END IF;

    RETURN NEXT;
END;
$$;

-- Fix _ethiopian_to_jdn: correct leap-year check when validating Pagumē (month 13) input
CREATE OR REPLACE FUNCTION _ethiopian_to_jdn(e_year integer, e_month integer, e_day integer)
RETURNS integer
LANGUAGE plpgsql
IMMUTABLE STRICT
AS $$
DECLARE
    ethiopian_epoch constant integer := 1724221;
    era integer;
    year_of_era integer;
    day_of_year integer;
    is_leap boolean;
    max_days integer;
BEGIN
    IF e_year < 1 THEN
        RAISE EXCEPTION 'Invalid Ethiopian year: % (must be >= 1)', e_year
            USING ERRCODE = 'datetime_field_overflow';
    END IF;

    IF e_month < 1 OR e_month > 13 THEN
        RAISE EXCEPTION 'Invalid Ethiopian month: % (must be 1-13)', e_month
            USING ERRCODE = 'datetime_field_overflow';
    END IF;

    IF e_day < 1 THEN
        RAISE EXCEPTION 'Invalid Ethiopian day: % (must be >= 1)', e_day
            USING ERRCODE = 'datetime_field_overflow';
    END IF;

    IF e_month <= 12 THEN
        IF e_day > 30 THEN
            RAISE EXCEPTION 'Invalid Ethiopian day: % (month % has 30 days)', e_day, e_month
                USING ERRCODE = 'datetime_field_overflow';
        END IF;
    ELSE
        is_leap := (e_year % 4 = 0);
        max_days := CASE WHEN is_leap THEN 6 ELSE 5 END;
        IF e_day > max_days THEN
            RAISE EXCEPTION 'Invalid Ethiopian day: % (month 13 has % days in year %)', e_day, max_days, e_year
                USING ERRCODE = 'datetime_field_overflow';
        END IF;
    END IF;

    era := (e_year - 1) / 4;
    year_of_era := (e_year - 1) % 4;

    IF e_month <= 12 THEN
        day_of_year := (e_month - 1) * 30 + (e_day - 1);
    ELSE
        day_of_year := 360 + (e_day - 1);
    END IF;

    RETURN ethiopian_epoch + era * 1461 + year_of_era * 365 + day_of_year;
END;
$$;

DO $$
BEGIN
    RAISE NOTICE 'Ethiopian calendar functions upgraded to version %', ethiopian_calendar_version();
END;
$$;
