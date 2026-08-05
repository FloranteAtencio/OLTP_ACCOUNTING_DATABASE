BEGIN;

    CREATE OR REPLACE FUNCTION Audit.WORM()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
    BEGIN
        
        RAISE EXCEPTION 'Direct Operation of Update and Delete is Prohibited';

    IF TG_OP = 'DELETE' THEN   
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;

    END;
    $$;

    CREATE TRIGGER Guard_worms
    BEFORE UPDATE OR DELETE ON Audit.record_lineage
    FOR EACH ROW EXECUTE FUNCTION Audit.WORM();

COMMIT;

SELECT '33 WORM' AS STATUS;
