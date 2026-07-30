BEGIN;

CREATE OR REPLACE PROCEDURE Staging.import_workflow_validation(
    IN p_session_id INT
)
LANGUAGE plpgsql as $$
DECLARE
    table_related VARCHAR;
    new_session_id INT;
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
    EXECUTE format(
        '
        UPDATE Staging.import_workflows a
        SET
            new_state = %L,
            previous_state = %L,
            notes = %L
        FROM %s b 
        WHERE a.session_id = b.session_id
        AND b.session_id = %L
        AND b.validation_status = %L;
        ',
        'VALID',
        'PENDING',
        'PENDING FOR APPROVAL',
        table_related,
        new_session_id,
        'VALID'
        );

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Staging import workflow validation failed: %', SQLERRM;
END;
$$;

COMMIT;

SELECT 'Staging Schema import data validations complete' as Status;
