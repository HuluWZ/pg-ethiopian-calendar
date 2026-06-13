-- Ethiopian Calendar Upgrade: 1.1.0/1.1.1 → 1.1.2
-- Fixes: version string sync, pre-epoch validation in to_ethiopian_date/timestamp/datetime

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'ethiopian_calendar_version') THEN
        RAISE NOTICE 'Current version: %', ethiopian_calendar_version();
    ELSE
        RAISE NOTICE 'No version function found - assuming pre-1.1.0';
    END IF;
END;
$$;

-- Fix version string (was '1.1.0', now '1.1.2')
CREATE OR REPLACE FUNCTION ethiopian_calendar_version()
RETURNS text LANGUAGE sql IMMUTABLE AS $$ SELECT '1.1.2'::text; $$;

-- Fix to_ethiopian_date: reject dates before Ethiopian epoch
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

-- Fix to_ethiopian_timestamp: reject dates before Ethiopian epoch
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

DO $$
BEGIN
    RAISE NOTICE 'Ethiopian calendar functions upgraded to version %', ethiopian_calendar_version();
END;
$$;
