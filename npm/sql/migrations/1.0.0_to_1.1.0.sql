-- Ethiopian Calendar Upgrade: 1.0.0 → 1.1.0
-- Changes: error handling, validation, version function, no-arg overloads

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'ethiopian_calendar_version') THEN
        RAISE NOTICE 'Current version: %', ethiopian_calendar_version();
    ELSE
        RAISE NOTICE 'No version function found - assuming pre-1.1.0';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION ethiopian_calendar_version()
RETURNS text LANGUAGE sql IMMUTABLE AS $$ SELECT '1.1.0'::text; $$;

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
        is_leap := (e_year % 4 = 3);
        max_days := CASE WHEN is_leap THEN 6 ELSE 5 END;
        IF e_day > max_days THEN e_day := max_days; END IF;
    END IF;
    
    RETURN NEXT;
END;
$$;

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
        is_leap := (e_year % 4 = 3);
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

CREATE OR REPLACE FUNCTION to_ethiopian_date(ts timestamp)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE STRICT
AS $$
DECLARE
    ethiopian_epoch_jdn constant integer := 1724221;
    jdn integer;
    eth record;
BEGIN
    jdn := _gregorian_to_jdn(
        EXTRACT(YEAR FROM ts)::integer,
        EXTRACT(MONTH FROM ts)::integer,
        EXTRACT(DAY FROM ts)::integer
    );
    
    IF jdn < ethiopian_epoch_jdn THEN
        RAISE EXCEPTION 'Date % is before Ethiopian calendar epoch (August 29, 8 CE)', ts::date
            USING ERRCODE = 'datetime_field_overflow';
    END IF;
    
    SELECT * INTO eth FROM _jdn_to_ethiopian(jdn);
    
    RETURN to_char(eth.e_year, 'FM0000') || '-' || 
           to_char(eth.e_month, 'FM00') || '-' || 
           to_char(eth.e_day, 'FM00');
END;
$$;

CREATE OR REPLACE FUNCTION to_ethiopian_date()
RETURNS text LANGUAGE sql STABLE AS $$ SELECT to_ethiopian_date(NOW()::timestamp); $$;

CREATE OR REPLACE FUNCTION to_ethiopian_timestamp(ts timestamp)
RETURNS timestamp
LANGUAGE plpgsql
IMMUTABLE STRICT
AS $$
DECLARE
    ethiopian_epoch_jdn constant integer := 1724221;
    jdn integer;
    eth record;
    time_part time;
BEGIN
    jdn := _gregorian_to_jdn(
        EXTRACT(YEAR FROM ts)::integer,
        EXTRACT(MONTH FROM ts)::integer,
        EXTRACT(DAY FROM ts)::integer
    );
    time_part := ts::time;
    
    IF jdn < ethiopian_epoch_jdn THEN
        RAISE EXCEPTION 'Date % is before Ethiopian calendar epoch (August 29, 8 CE)', ts::date
            USING ERRCODE = 'datetime_field_overflow';
    END IF;
    
    SELECT * INTO eth FROM _jdn_to_ethiopian(jdn);
    
    RETURN make_timestamp(
        eth.e_year,
        eth.e_month,
        eth.e_day,
        EXTRACT(HOUR FROM time_part)::integer,
        EXTRACT(MINUTE FROM time_part)::integer,
        EXTRACT(SECOND FROM time_part)
    );
END;
$$;

CREATE OR REPLACE FUNCTION to_ethiopian_timestamp()
RETURNS timestamp LANGUAGE sql STABLE AS $$ SELECT to_ethiopian_timestamp(NOW()::timestamp); $$;

CREATE OR REPLACE FUNCTION from_ethiopian_date(ethiopian_date text)
RETURNS timestamp
LANGUAGE plpgsql
IMMUTABLE STRICT
AS $$
DECLARE
    parts text[];
    e_year integer;
    e_month integer;
    e_day integer;
    jdn integer;
    greg record;
BEGIN
    IF ethiopian_date IS NULL OR trim(ethiopian_date) = '' THEN
        RAISE EXCEPTION 'Ethiopian date cannot be NULL or empty'
            USING ERRCODE = 'null_value_not_allowed';
    END IF;
    
    parts := string_to_array(trim(ethiopian_date), '-');
    
    IF array_length(parts, 1) IS NULL OR array_length(parts, 1) != 3 THEN
        RAISE EXCEPTION 'Invalid Ethiopian date format: "%" (expected YYYY-MM-DD)', ethiopian_date
            USING ERRCODE = 'invalid_datetime_format';
    END IF;
    
    BEGIN
        e_year := parts[1]::integer;
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Invalid Ethiopian year: "%" (must be a number)', parts[1]
            USING ERRCODE = 'invalid_datetime_format';
    END;
    
    BEGIN
        e_month := parts[2]::integer;
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Invalid Ethiopian month: "%" (must be a number)', parts[2]
            USING ERRCODE = 'invalid_datetime_format';
    END;
    
    BEGIN
        e_day := parts[3]::integer;
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Invalid Ethiopian day: "%" (must be a number)', parts[3]
            USING ERRCODE = 'invalid_datetime_format';
    END;
    
    jdn := _ethiopian_to_jdn(e_year, e_month, e_day);
    SELECT * INTO greg FROM _jdn_to_gregorian(jdn);
    
    RETURN make_timestamp(greg.g_year, greg.g_month, greg.g_day, 0, 0, 0);
END;
$$;

DO $$
BEGIN
    RAISE NOTICE 'Ethiopian calendar functions upgraded to version %', ethiopian_calendar_version();
END;
$$;
