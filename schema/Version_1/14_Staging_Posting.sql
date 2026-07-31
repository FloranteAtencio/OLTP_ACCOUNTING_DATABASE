BEGIN;

CREATE OR REPLACE PROCEDURE Staging.post_ar_import( IN p_session_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD;
    new_previous_state VARCHAR(50);

BEGIN    

    SET LOCAL app.allow_direct_insert = 'true';
    
    SELECT new_state INTO new_previous_state
    FROM Staging.import_workflows a
    WHERE a.session_id = p_session_id
    LIMIT 1;
    
    FOR r IN
        SELECT a.*
        FROM Staging.stg_ar_imports a
        LEFT JOIN Staging.import_workflows b ON a.id = b.staging_record_id 
        WHERE a.session_id = p_session_id
          AND validation_status = 'VALID'
          AND b.new_state = 'APPROVE_L3'
    LOOP
        CALL Finance.ar_transaction(
            r.client_code::INT,
            r.customer_code::INT,
            r.due_date::DATE,
            r.invoice_date::DATE,
            r.amount::DECIMAL,
            r.status::VARCHAR,
            gen_random_uuid()::TEXT
        );
    END LOOP;
    
    UPDATE staging.import_workflows
    SET new_state = 'POSTED',
        previous_state = new_previous_state
    WHERE session_id = p_session_id AND new_state = 'APPROVED_L3';

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Staging post for ar import failed : % ', SQLERRM;

END;
$$;

CREATE OR REPLACE PROCEDURE Staging.import_workflow_posting(
    IN p_session_id INT
)
LANGUAGE plpgsql AS $$
DECLARE
    new_session_id INT;
    table_related VARCHAR;
BEGIN
    
    SELECT session_id INTO new_session_id
    FROM Audit.import_sessions a
    WHERE a.session_id = p_session_id
    LIMIT 1;
    
    SELECT Staging.table_verification(new_session_id) INTO table_related;

    IF new_session_id IS NULL THEN
        RAISE EXCEPTION 'invalid Session ID : %', new_session_id;
    END IF;

    IF table_related IS NULL THEN   
        RAISE EXCEPTION 'Invalid table referecne : %',table_related;
    END IF;

    PERFORM 1 FROM Audit.import_sessions WHERE session_id = p_session_id;

    IF table_related = 'Staging.stg_ar_imports' THEN
        CALL Staging.post_ar_import(new_session_id);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Staging main post transaction failed : % ', SQLERRM;

END;
$$;
COMMIT;

SELECT 'Staging Schema import data posting complete' as Status;
