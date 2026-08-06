BEGIN;

CREATE OR REPLACE FUNCTION Audit.import_validation(
    p_session_id INT,
    p_row_number INT,
    p_field_name VARCHAR,
    p_validation_rule VARCHAR,
    p_actual_value TEXT,
    p_is_valid BOOLEAN,
    p_severity VARCHAR
)
RETURNS BIGINT AS $$
DECLARE

    new_id BIGINT;

BEGIN

    INSERT INTO Audit.import_validation_log(
        session_id
        ,row_number
        ,field_name
        ,validation_rule 
        ,actual_value 
        ,is_valid 
        ,severity -- 'ERROR', 'WARNING', 'INFO'
        
    )
    VALUES(
        p_session_id
        , p_row_number
        , p_field_name
        , p_validation_rule
        , p_actual_value
        , p_is_valid
        , p_severity
        
    )
    RETURNING validation_id INTO new_id;

    RETURN new_id;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;

-- Function to start an import session
-- This is the very first function needed to call
DROP FUNCTION IF EXISTS Audit.start_import_session(INT, VARCHAR, VARCHAR, VARCHAR) CASCADE;
CREATE FUNCTION Audit.start_import_session(
    p_client_id INT,
    p_import_type VARCHAR,
    p_imported_by VARCHAR,
    p_source_file VARCHAR DEFAULT NULL
)
RETURNS INT AS $$
DECLARE
    v_session_id INT;
BEGIN
    INSERT INTO Audit.import_sessions (client_id, import_type, imported_by, source_file, status)
    VALUES (p_client_id, p_import_type, p_imported_by, p_source_file, 'IN_PROGRESS')
    RETURNING session_id INTO v_session_id;
    
    RETURN v_session_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;

-- Function to log an import record
-- This is the function where you need to call after the after the process in the main schema table related.
DROP FUNCTION IF EXISTS Audit.log_import_record(INT, INT, VARCHAR, JSONB, VARCHAR, TEXT, INT) CASCADE;
CREATE FUNCTION Audit.log_import_record(
    p_session_id INT,
    p_row_number INT,
    p_table_name VARCHAR,
    p_record_data JSONB,
    p_status VARCHAR,
    p_error_message TEXT DEFAULT NULL,
    p_created_record_id INT DEFAULT NULL
)
RETURNS BIGINT AS $$
DECLARE
    v_detail_id BIGINT;
BEGIN
    INSERT INTO Audit.import_detail_logs (
        session_id, row_number, table_name, record_data, 
        status, error_message, created_record_id
    )
    VALUES (p_session_id, p_row_number, p_table_name, p_record_data, 
            p_status, p_error_message, p_created_record_id)
    RETURNING detail_id INTO v_detail_id;
    
    -- Update import session counts
    UPDATE Audit.import_sessions
    SET total_records = total_records + 1,
        successful_records = CASE WHEN p_status = 'SUCCESS' THEN successful_records + 1 ELSE successful_records END,
        failed_records = CASE WHEN p_status = 'FAILED' THEN failed_records + 1 ELSE failed_records END
    WHERE session_id = p_session_id;
    
    RETURN v_detail_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;

-- Function to complete an import session
DROP FUNCTION IF EXISTS Audit.complete_import_session(INT, VARCHAR, TEXT) CASCADE;
CREATE FUNCTION Audit.complete_import_session(
    p_session_id INT,
    p_final_status VARCHAR,
    p_error_summary TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE Audit.import_sessions
    SET status = p_final_status,
        completed_at = CURRENT_TIMESTAMP,
        error_summary = p_error_summary
    WHERE session_id = p_session_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;

COMMIT;

SELECT '19 Audit log functions' as STATUS;