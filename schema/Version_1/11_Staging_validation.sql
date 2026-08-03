BEGIN;

CREATE OR REPLACE PROCEDURE Staging.import_workflow_validation(
    IN p_session_id INT
)
LANGUAGE plpgsql as $$
DECLARE
    table_related VARCHAR;
    new_session_id INT;
    r RECORD;
    z RECORD;
BEGIN

    SELECT session_id INTO new_session_id
    FROM Audit.import_sessions a
    WHERE a.session_id = p_session_id
    LIMIT 1;

    SELECT Staging.table_verification(new_session_id) INTO table_related;

    IF table_related IS NULL THEN
        RAISE EXCEPTION 'Invalid table name: %', table_related;
    END IF;

    IF new_session_id IS NULL THEN
        RAISE EXCEPTION 'invalid Session ID : %', new_session_id;
    END IF;

    PERFORM 1 FROM Audit.import_sessions WHERE session_id = p_session_id;

    FOR r IN
        SELECT  a.*
                , b.row_number
        FROM Staging.stg_ar_imports a
        LEFT JOIN Staging.import_workflows b ON a.id = b.staging_record_id 
        LEFT JOIN Staging.import_detail_logs c ON c.row_number = b.row_number
        WHERE a.session_id = p_session_id
          AND validation_status = 'VALID'
          AND b.new_state = 'PENDING'
    LOOP

        PERFORM Compliance.validate_ar_import(
            r.row_number::INT,
            r.customer_code::INT,
            r.amount::DECIMAL,
            r.invoice_date::DATE,
            r.due_date::DECIMAL,
            r.status::VARCHAR
        );

    END LOOP;    

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Staging import workflow validation failed: %', SQLERRM;
END;
$$;

COMMIT;

SELECT 'Staging Schema import data validations complete' as Status;
