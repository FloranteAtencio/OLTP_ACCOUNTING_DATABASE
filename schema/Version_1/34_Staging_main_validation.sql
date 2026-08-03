-- =====================================
-- the main staging work flow santation
-- =====================================

CREATE OR REPLACE PROCEDURE Staging.main_import_workflow_validation(
    IN p_session_id INT
)
LANGUAGE plpgsql AS $$
DECLARE
    table_related VARCHAR;
    new_session_id INT;
BEGIN

    -- 1. Validate Session ID
    SELECT session_id INTO new_session_id
    FROM Audit.import_sessions
    WHERE session_id = p_session_id
    LIMIT 1;

    IF new_session_id IS NULL THEN
        RAISE EXCEPTION 'Invalid Session ID: %', p_session_id;
    END IF;

    SELECT Staging.table_verification(new_session_id) INTO table_related;
 
    -- 2. Validate Table Name (Whitelist approach)
    IF table_related IS NULL THEN
        RAISE EXCEPTION 'Invalid table name: %. Not Allowed:', table_related;
    END IF;
    
    PERFORM 1 FROM Audit.import_sessions WHERE session_id = p_session_id;
    
    -- 3. Execute Table-Specific Sanitation
    IF table_related = 'Staging.stg_ar_imports' THEN
        CALL Staging.ar_import_workflow_validation(new_session_id);
        
    ELSIF table_related = 'stg_other_table' THEN
        RAISE EXCEPTION 'Sanitation logic for stg_other_table is not yet implemented.';
            
    END IF;

 -- Ensure we only update records for this session
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Staging import Main Validations failed for session %: %', p_session_id, SQLERRM;
END;
$$;
