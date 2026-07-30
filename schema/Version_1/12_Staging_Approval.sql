BEGIN;

CREATE OR REPLACE PROCEDURE Staging.import_workflow_approval_L1(
    IN p_session_id INT,
    -- IN p_level SMALLINT, --1 , 2 3
    -- IN p_status  VARCHAR(20), -- APPROVE_L1,APPROVE_L2,APPROVE_L3
    IN p_approve_by VARCHAR(20) -- MANAGER, BOOKKEEPER, ACCOUNTANT
)
LANGUAGE plpgsql as $$
DECLARE
    new_session_id INT;
    new_previous_state VARCHAR(50);
BEGIN

    SELECT session_id INTO new_session_id
    FROM Audit.import_sessions a
    WHERE a.session_id = p_session_id
    LIMIT 1;

    SELECT new_state INTO new_previous_state
    FROM Staging.import_workflows a
    WHERE a.session_id = p_session_id
    LIMIT 1;
    
    IF new_session_id IS NULL THEN
        RAISE EXCEPTION 'Please Check Session_id provided!';
    END IF;

    -- IF p_status NOT IN ('APPROVE_L1','APPROVE_L2','APPROVE_L3') THEN
    --     RAISE EXCEPTION 'Please Check approve state: APPROVE_L1, APPROVE_L2, APPROVE_L3';
    -- END IF;

    PERFORM 1 FROM Audit.import_sessions a where a.session_id = p_session_id;

    INSERT INTO Staging.import_approvals (session_id, staging_record_id,approval_status,approval_level,approved_by)
    SELECT  a.session_id,
            a.staging_record_id,
            'APPROVE_L1',
            1,
            p_approve_by
    FROM Staging.import_workflows a 
    WHERE a.new_state = 'VALID' AND a.session_id = new_session_id;

    UPDATE Staging.import_workflows
    SET new_state = 'APPROVE_L1',
        previous_state = new_previous_state
    WHERE session_id = new_session_id AND new_state = 'VALID';

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Staging import approval_l1 failed: %', SQLERRM;
END;
$$;

CREATE OR REPLACE PROCEDURE Staging.import_workflow_approval_L2(
    IN p_session_id INT,
    -- IN p_level SMALLINT, --1 , 2 3
    -- IN p_status  VARCHAR(20), -- APPROVE_L1,APPROVE_L2,APPROVE_L3
    IN p_approve_by VARCHAR(20) -- MANAGER, BOOKKEEPER, ACCOUNTANT
)
LANGUAGE plpgsql as $$
DECLARE
    new_session_id INT;
    new_previous_state VARCHAR(50);
BEGIN

    SELECT session_id INTO new_session_id
    FROM Audit.import_sessions a
    WHERE a.session_id = p_session_id
    LIMIT 1;

    SELECT new_state INTO new_previous_state
    FROM Staging.import_workflows a
    WHERE a.session_id = p_session_id
    LIMIT 1;
    
    IF new_session_id IS NULL THEN
        RAISE EXCEPTION 'Please Check Session_id provided!';
    END IF;

    -- IF p_status NOT IN ('APPROVE_L1','APPROVE_L2','APPROVE_L3') THEN
    --     RAISE EXCEPTION 'Please Check approve state: APPROVE_L1, APPROVE_L2, APPROVE_L3';
    -- END IF;

    PERFORM 1 FROM Audit.import_sessions a where a.session_id = p_session_id;

    -- INSERT INTO Staging.import_approvals (session_id, staging_record_id,approval_status,approval_level,approved_by)
    -- SELECT  a.session_id,
    --         a.staging_record_id,
    --         'APPROVE_L2',
    --         2,
    --         p_approve_by
    -- FROM Staging.import_workflows a 
    -- WHERE a.new_state = 'APPROVE_L1' AND a.session_id = new_session_id;

    UPDATE Staging.import_approvals
    SET
        approval_status = 'APPROVE_L2',
        approval_level = 2,
        approved_by = p_approve_by
    WHERE approval_status = 'APPROVE_L1' AND session_id = new_session_id;

    UPDATE import_workflows
    SET new_state = 'APPROVE_L2',
        previous_state = new_previous_state
    WHERE session_id = new_session_id AND new_state = 'APPROVE_L1';

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Staging import approval_l2 failed: %', SQLERRM;
END;
$$;

CREATE OR REPLACE PROCEDURE Staging.import_workflow_approval_L3(
    IN p_session_id INT,
    -- IN p_level SMALLINT, --1 , 2 3
    -- IN p_status  VARCHAR(20), -- APPROVE_L1,APPROVE_L2,APPROVE_L3
    IN p_approve_by VARCHAR(20) -- MANAGER, BOOKKEEPER, ACCOUNTANT
)
LANGUAGE plpgsql as $$
DECLARE
    new_session_id INT;
    new_previous_state VARCHAR(50);
BEGIN

    SELECT session_id INTO new_session_id
    FROM Audit.import_sessions a
    WHERE a.session_id = p_session_id
    LIMIT 1;

    SELECT new_state INTO new_previous_state
    FROM Staging.import_workflows a
    WHERE a.session_id = p_session_id
    LIMIT 1;
    
    IF new_session_id IS NULL THEN
        RAISE EXCEPTION 'Please Check Session_id provided!';
    END IF;

    -- IF p_status NOT IN ('APPROVE_L1','APPROVE_L2','APPROVE_L3') THEN
    --     RAISE EXCEPTION 'Please Check approve state: APPROVE_L1, APPROVE_L2, APPROVE_L3';
    -- END IF;

    PERFORM 1 FROM Audit.import_sessions a where a.session_id = p_session_id;

    -- INSERT INTO Staging.import_approvals (session_id, staging_record_id,approval_status,approval_level,approved_by)
    -- SELECT  a.session_id,
    --         a.staging_record_id,
    --         'APPROVE_L3',
    --         3,
    --         p_approve_by
    -- FROM Staging.import_workflows a 
    -- WHERE a.new_state = 'APPROVE_L2' AND a.session_id = new_session_id;
    
    UPDATE Staging.import_approvals
    SET
        approval_status = 'APPROVE_L3',
        approval_level = 3,
        approved_by = p_approve_by
    WHERE approval_status = 'APPROVE_L2' AND session_id = new_session_id;

    UPDATE import_workflows
    SET new_state = 'APPROVE_L3',
        previous_state = new_previous_state
    WHERE session_id = new_session_id AND new_state = 'APPROVE_L2';

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Staging import approval_l3 failed : %', SQLERRM;
END;
$$;

COMMIT;

SELECT 'Staging Schema import data approval complete' as Status;
