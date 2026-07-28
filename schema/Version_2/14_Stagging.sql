-- =======================================================================
-- 14. STAGING SHCEMA PART 
-- this stagging schema is for validation, sanitation and approval matters!
-- ====================================================================

SELECT '14. StagGing schema Start' as  Status;

BEGIN;

CREATE SCHEMA Staging;

-- 1. STAGING TABLE
CREATE TABLE IF NOT EXISTS Staging.stg_ar_imports(
    id BIGSERIAL PRIMARY KEY,
    session_id INT,
    customer_code TEXT,
    client_code TEXT,
    amount TEXT,
    invoice_date TEXT,
    due_date TEXT,
    status TEXT,
    validation_status VARCHAR(20),
    validation_errors TEXT,
    imported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. WORKFLOW TABLE
CREATE TABLE IF NOT EXISTS Staging.import_workflows (
    session_id INT,
    staging_record_id BIGINT,
    staging_table VARCHAR(50),
    previous_state VARCHAR(50),
    new_state VARCHAR(50),
    changed_by VARCHAR(100),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- 3. APPROVAL TABLE
CREATE TABLE Staging.import_approvals (
    session_id INT,
    staging_record_id BIGINT,   

    approval_level SMALLINT,
    approval_status VARCHAR(20),

    approved_by VARCHAR(100),
    approved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    comments TEXT
);
-- =============================================
-- this area is for import for each staging table
-- you can add more functions
-- ==============================================
DROP FUNCTION IF EXISTS Staging.ar_import_data(INT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT) CASCADE;
CREATE FUNCTION Staging.ar_import_data(
    p_session_id INT,
    p_client_id TEXT,
    p_customer_id TEXT ,
    p_invoice_date TEXT,
    p_due_date TEXT,
    p_amount TEXT,
    p_status TEXT

)
RETURNS INT AS $$
DECLARE
    new_ar_staging_id INT;
BEGIN
    INSERT INTO Staging.stg_ar_imports( 
        session_id, 
        client_code,
        customer_code, 
        invoice_date, 
        due_date, 
        amount,
        status, 
        validation_status, 
        validation_errors, 
        imported_at) 
    VALUES ( p_session_id, p_client_id, p_customer_id, p_invoice_date,  p_due_date, p_amount, p_status, 'DRAFT', NULL, NOW())
    RETURNING id INTO new_ar_staging_id;

    INSERT INTO Staging.import_workflows
    (session_id, staging_record_id, staging_table,previous_state, new_state, changed_by)
    VALUES(p_session_id, new_ar_staging_id, 'ar_import_data',NULL, 'DRAFT',current_user);

    RETURN new_ar_staging_id;
END; 
$$ LANGUAGE plpgsql;
DROP FUNCTION IF EXISTS Staging.table_verification(INT);

-- ===================================================
-- This is where you can add and change the table returns for dynamic programming
-- just add if conditions inside the table verification
-- ===================================================
CREATE FUNCTION Staging.table_verification(
    p_session_id INT
)
RETURNS VARCHAR AS $$
DECLARE
    v_table_name VARCHAR;
BEGIN

    IF EXISTS (
        SELECT 1 
        FROM Staging.stg_ar_import a 
        WHERE a.session_id = p_session_id
    ) THEN
        RETURN 'Staging.stg_ar_import'; -- Fixed typo in string and removed extra dot
    END IF;

    RETURN NULL; -- Explicit return if no match found
END;
$$ LANGUAGE plpgsql;

-- =====================================
-- add more procedure for sanitation for each staging table
-- =====================================

CREATE OR REPLACE PROCEDURE Staging.ar_sanitation(
    p_session_id INT
)
LANGUAGE plpgsql as $$
DECLARE
BEGIN

    UPDATE Staging.stg_ar_imports s
    SET 
        validation_status = CASE 
            WHEN b.customer_id IS NULL THEN 'INVALID'
            WHEN c.client_id IS NULL THEN 'INVALID'
            WHEN s.amount !~ '^[0-9.]+$' THEN 'INVALID'
            WHEN s.invoice_date !~ '^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$' THEN 'INVALID'  
            WHEN s.due_date !~ '^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$' THEN 'INVALID'
            WHEN s.status NOT IN ('Pending', 'Paid', 'Overdue','Returned','Partially Returned','Partially Paid') THEN 'INVALID'
            ELSE 'VALID'
        END,
        validation_errors = CASE 
            WHEN b.customer_id IS NULL THEN 'Customer not found'
            WHEN c.client_id IS NULL THEN 'Client not found'
            WHEN s.amount !~ '^[0-9.]+$' THEN 'Invalid amount format'
            WHEN s.invoice_date !~ '^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$' THEN 'Invalid Date'  
            WHEN s.due_date !~ '^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$' THEN 'Invalid Date'
            WHEN s.status NOT IN ('Pending', 'Paid', 'Overdue','Returned','Partially Returned','Partially Paid') THEN 'INVALID'
            ELSE NULL
        END
    FROM Finance.clients c,
        Finance.customers b
    WHERE
        c.client_id = s.client_code::INT
    AND b.customer_id = s.customer_code::INT
    AND s.session_id = p_session_id
    AND s.validation_status = 'DRAFT';

    
    UPDATE Staging.import_workflows a
    SET
        new_state = 'PENDING',
        previous_state = 'DRAFT',
        notes = 'PENDING FOR VALIDATION'
    FROM Staging.stg_ar_imports b
    WHERE a.staging_record_id = b.id 
    AND a.session_id = b.session_id
    AND b.validation_status = 'VALID'
    AND a.session_id = p_session_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Account Receivables Sanitations Failed: %', SQLERRM;

END;
$$;

-- =====================================
-- the main staging work flow santation
-- =====================================

CREATE OR REPLACE PROCEDURE Staging.import_workflow_sanitation(
    IN p_session_id INT
)
LANGUAGE plpgsql AS $$
DECLARE
    table_related VARCHAR;
    new_session_id INT;
BEGIN
    -- 1. Validate Session ID
    SELECT session_id INTO new_session_id
    FROM Finance.import_sessions
    WHERE session_id = p_session_id
    LIMIT 1;

    IF new_session_id IS NULL THEN
        RAISE EXCEPTION 'Invalid Session ID: %', p_session_id;
    END IF;

    table_related := Staging.table_verification(new_session_id);
 
    -- 2. Validate Table Name (Whitelist approach)
    IF table_related IS NULL THEN
        RAISE EXCEPTION 'Invalid table name: %. Not Allowed:', table_related;
    END IF;

    -- 3. Execute Table-Specific Sanitation
    IF table_related = 'Staging.stg_ar_imports' THEN
        CALL Staging.ar_sanitation(new_session_id);

    ELSIF table_related = 'stg_other_table' THEN
        RAISE EXCEPTION 'Sanitation logic for stg_other_table is not yet implemented.';
        RETURN;    
    END IF;

 -- Ensure we only update records for this session
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Staging import sanitation failed for session %: %', p_session_id, SQLERRM;
END;
$$;

-- =====================================
-- main validations workflow
-- =====================================

CREATE OR REPLACE PROCEDURE Staging.import_workflow_validation(
    IN p_session_id INT
)
LANGUAGE plpgsql as $$
DECLARE
    table_related VARCHAR;
    new_session_id INT;
    use_table TEXT;
BEGIN
    use_table = 'Staging.'||table_related;

    SELECT session_id INTO new_session_id
    FROM Finance.import_sessions a
    WHERE a.session_id = p_session_id
    LIMIT 1;

    table_related := Staging.table_verification(new_session_id);

    IF table_related IS NULL THEN
        RAISE EXCEPTION 'Invalid table name: %', table_related;
    END IF;

    IF new_session_id IS NULL THEN
        RAISE EXCEPTION 'invalid Session ID : %', new_session_id;
    END IF;

    PERFORM 1 FROM Finance.import_sessions WHERE session_id = p_session_id;
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
        use_table,
        p_session_id,
        'VALID'
        );

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Staging import workflow validation failed: %', SQLERRM;
END;
$$;

CREATE OR REPLACE PROCEDURE Staging.import_workflow_approval(
    IN p_session_id INT,
    IN p_level SMALLINT,
    IN p_status  VARCHAR(20),
    IN p_approve_by VARCHAR(20),
    IN p_approve_state VARCHAR(20)
)
LANGUAGE plpgsql as $$
DECLARE
    new_session_id INT;
    new_previous_state VARCHAR(50);
BEGIN

    SELECT session_id INTO new_session_id
    FROM Finance.import_sessions a
    WHERE a.session_id = p_session_id
    LIMIT 1;

    SELECT new_state INTO new_previous_state
    FROM Staging.import_workflow a
    WHERE a.session_id = p_session_id
    LIMIT 1;
    
    IF new_session_id IS NULL THEN
        RAISE EXCEPTION 'Please Check Session_id provided!';
    END IF;

    IF p_approve_state NOT IN ('APPROVE_L1','APPROVE_L2','APPROVE_L3') THEN
        RAISE EXCEPTION 'Please Check approve state: APPROVE_L1, APPROVE_L2, APPROVE_L3';
    END IF;

    PERFORM 1 FROM Finance.import_sessions a where a.session_id = p_session_id;

    INSERT INTO Staging.import_approvals (session_id, staging_record_id,approval_status,approval_level,approved_by)
    SELECT  a.session_id,
            a.staging_record_id,
            p_status,
            p_level,
            p_approve_by
    FROM Staging.import_workflow a 
    WHERE a.new_state = 'VALID' AND a.session_id = new_session_id;

    UPDATE import_workflow
    SET new_state = p_approve_state,
        previous_state = new_previous_state
    WHERE session_id = new_session_id AND new_state = new_previous_state;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Staging import approval failed: %', SQLERRM;
END;
$$;

CREATE OR REPLACE  PROCEDURE Staging.import_workflow_reject(
    IN p_session_id INT
)
LANGUAGE plpgsql AS $$
DECLARE
    new_session_id INT;
BEGIN
    SELECT a.session_id INTO new_session_id
    FROM Finance.import_sessions a
    WHERE a.session_id = p_session_id
    LIMIT 1;

    IF new_session_id IS NULL THEN 
        RAISE EXCEPTION 'Session ID not valid';
    END IF;

    PERFORM 1 FROM Finance.import_sessions WHERE session_id = p_session_id;

    UPDATE Staging.import_workflows a
    SET
        new_state = 'REJECT',
        previous_state = 'DRAFT'
    WHERE a.session_id = new_session_id;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Staging import workflows Rejection Failed % ', SQLERRM;
END;
$$;

CREATE OR REPLACE PROCEDURE Staging.post_ar_import(p_session_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD;
    new_previous_state VARCHAR(50);

BEGIN    
    
    SELECT new_state INTO new_previous_state
    FROM Staging.import_workflow a
    WHERE a.session_id = p_session_id
    LIMIT 1;
    
    FOR r IN
        SELECT *
        FROM Staging.stg_ar_import
        WHERE session_id = p_session_id
          AND validation_status = 'APPROVED_L3'
    LOOP
        CALL Finance.ar_transaction(
            r.client_id,
            r.customer_id,
            r.due_date::DATE,
            r.invoice_date::DATE,
            r.amount::DECIMAL,
            r.status,
            gen_random_uuid()::TEXT
        );
    END LOOP;
    
    UPDATE import_workflow
    SET new_state = 'POSTED',
        previous_state = new_previous_state
    WHERE session_id = new_session_id AND new_state = new_previous_state;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Staging post for ar import failed % ', SQLERRM;

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
    FROM Finance.import_sessions a
    WHERE a.session_id = p_session_id
    LIMIT 1;
    
    SELECT Staging.table_verification(new_session_id) INTO table_related;

    IF new_session_id IS NULL THEN
        RAISE EXCEPTION 'invalid Session ID : %', new_session_id;
    END IF;

    IF table_related IS NULL THEN   
        RAISE EXCEPTION 'Invalid table referecne : %',table_related;
    END IF;

    PERFORM 1 FROM Finance.import_sessions WHERE session_id = p_session_id;

    IF table_related = 'Staging.stg_ar_imports' THEN
        CALL Staging.post_ar_import(new_session_id);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Staging main post transaction failed % ', SQLERRM;

END;
$$;

COMMIT;

SELECT '14. Stagging schema COMPLETE!' as  Status;
