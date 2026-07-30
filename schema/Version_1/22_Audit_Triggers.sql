-- ============================================
-- 5. AUTO LINEAGE TRIGGER
-- ============================================

SELECT '15. STAGGING TRIGGERS START' as  Status;

BEGIN;

CREATE OR REPLACE FUNCTION Audit.auto_lineage_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF current_setting('app.import_session_id', TRUE) IS NOT NULL THEN
        INSERT INTO Audit.record_lineage (
            table_name, record_id, client_id, source_type, 
            source_file, import_session_id, created_by
        ) VALUES (
            TG_TABLE_NAME, 
            NEW.id::INT, 
            NEW.client_code::INT, 
            'SPREADSHEET_IMPORT',
            current_setting('app.import_source_file', TRUE),
            current_setting('app.import_session_id')::INT,
            current_user
        );
    ELSE
        INSERT INTO Audit.record_lineage (
            table_name, record_id, client_id, source_type, created_by
        ) VALUES (
            TG_TABLE_NAME, NEW.id::INT, NEW.client_code::INT, 'MANUAL_ENTRY', current_user
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_auto_lineage ON Staging.stg_ar_imports;
CREATE TRIGGER trg_auto_lineage
AFTER INSERT ON Staging.stg_ar_imports
FOR EACH ROW EXECUTE FUNCTION Audit.auto_lineage_trigger();


COMMIT;

SELECT '15. STAGGING TRIGGERS COMPLETE' as  Status;
