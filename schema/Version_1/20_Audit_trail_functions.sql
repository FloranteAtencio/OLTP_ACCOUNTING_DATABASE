BEGIN;

-- ============================================
-- 6. AUDIT TRAIL FUNCTIONS
-- ============================================

-- Record state change
DROP FUNCTION IF EXISTS Audit.record_state_change(INT, INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR) CASCADE;
CREATE FUNCTION Audit.record_state_change(
    p_transaction_id INT,
    p_client_id INT,
    p_new_state VARCHAR,
    p_state_reason VARCHAR,
    p_changed_by VARCHAR,
    p_notes VARCHAR DEFAULT NULL
)
RETURNS BIGINT AS $$
SECURITY DEFINER
SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;
DECLARE
    v_previous_state VARCHAR;
    v_lifecycle_id BIGINT;
BEGIN
    -- Get previous state
    SELECT new_state INTO v_previous_state
    FROM Audit.transaction_lifecycle
    WHERE transaction_id = p_transaction_id
    ORDER BY changed_at DESC
    LIMIT 1;
    
    -- Insert new state record
    INSERT INTO Audit.transaction_lifecycle (
        transaction_id, client_id, previous_state, new_state, 
        state_reason, changed_by, notes
    )
    VALUES (p_transaction_id, p_client_id, v_previous_state, p_new_state, 
            p_state_reason, p_changed_by, p_notes)
    RETURNING lifecycle_id INTO v_lifecycle_id;
    
    RETURN v_lifecycle_id;
END;
$$ LANGUAGE plpgsql;

-- Record approval
DROP FUNCTION IF EXISTS Audit.record_approval(INT, INT, INT, VARCHAR, VARCHAR, VARCHAR, TEXT) CASCADE;
CREATE FUNCTION Audit.record_approval(
    p_transaction_id INT,
    p_client_id INT,
    p_approval_level INT,
    p_approver_role VARCHAR,
    p_approver_name VARCHAR,
    p_status VARCHAR,
    p_comment TEXT DEFAULT NULL
)
RETURNS BIGINT AS $$
SECURITY DEFINER
SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;
DECLARE
    v_approval_id BIGINT;
BEGIN
    INSERT INTO Audit.approval_chain (
        transaction_id, client_id, approval_level, approver_role,
        approver_name, status, approval_comment, approved_at
    )
    VALUES (p_transaction_id, p_client_id, p_approval_level, p_approver_role,
            p_approver_name, p_status, p_comment,
            CASE WHEN p_status = 'APPROVED' THEN CURRENT_TIMESTAMP ELSE NULL END)
    RETURNING approval_id INTO v_approval_id;
    
    RETURN v_approval_id;
END;
$$ LANGUAGE plpgsql;

-- Record lineage
DROP FUNCTION IF EXISTS Audit.record_lineage_entry(VARCHAR, INT, INT, VARCHAR, VARCHAR, INT, INT, VARCHAR) CASCADE;
CREATE FUNCTION Audit.record_lineage_entry(
    p_table_name VARCHAR,
    p_record_id INT,
    p_client_id INT,
    p_source_type VARCHAR,
    p_created_by VARCHAR,
    p_import_session_id INT DEFAULT NULL,
    p_import_row_number INT DEFAULT NULL,
    p_source_file VARCHAR DEFAULT NULL
)
RETURNS BIGINT AS $$
SECURITY DEFINER
SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;
DECLARE
    v_lineage_id BIGINT;
BEGIN
    INSERT INTO Audit.record_lineage (
        table_name, record_id, client_id, source_type, source_file,
        import_session_id, import_row_number, created_by, created_at
    )
    VALUES (p_table_name, p_record_id, p_client_id, p_source_type, p_source_file,
            p_import_session_id, p_import_row_number, p_created_by, CURRENT_TIMESTAMP)
    RETURNING lineage_id INTO v_lineage_id;
    
    RETURN v_lineage_id;
END;
$$ LANGUAGE plpgsql;

COMMIT;

SELECT '20 Audit trail functions' AS STATUS;