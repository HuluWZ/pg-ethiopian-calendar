-- Ethiopian Calendar Upgrade: 1.1.2 → 1.1.3
-- Infrastructure-only release: Docker hardening, CI/CD pipeline, no SQL changes

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'ethiopian_calendar_version') THEN
        RAISE NOTICE 'Current version: %', ethiopian_calendar_version();
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION ethiopian_calendar_version()
RETURNS text LANGUAGE sql IMMUTABLE AS $$ SELECT '1.1.3'::text; $$;

DO $$
BEGIN
    RAISE NOTICE 'Ethiopian calendar functions upgraded to version %', ethiopian_calendar_version();
END;
$$;
