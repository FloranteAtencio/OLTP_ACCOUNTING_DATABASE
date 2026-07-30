-- ============================================
-- 7. COMPLETE AUDIT QUERY FUNCTIONS
-- ============================================

-- Get complete transaction audit
DROP FUNCTION IF EXISTS Finance.get_complete_transaction_audit(INT) CASCADE;
CREATE FUNCTION Finance.get_complete_transaction_audit(p_transaction_id INT)
RETURNS TABLE (
    audit_type VARCHAR,
    event_time TIMESTAMP,
    event_details TEXT,
    changed_by VARCHAR,
    status VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    -- State changes
    SELECT 
        'STATE_CHANGE'::VARCHAR,
        tl.changed_at,
        'State: ' || COALESCE(tl.previous_state, 'N/A') || ' → ' || tl.new_state || ' (' || tl.state_reason || ')'::TEXT,
        tl.changed_by,
        tl.new_state::VARCHAR
    FROM Finance.transaction_lifecycle tl
    WHERE tl.transaction_id = p_transaction_id
    
    UNION ALL
    
    -- Approvals
    SELECT 
        'APPROVAL'::VARCHAR,
        ac.created_at,
        'Level ' || ac.approval_level::TEXT || ': ' || ac.approver_role || ' - ' || ac.status::TEXT::TEXT,
        ac.approver_name,
        ac.status::VARCHAR
    FROM Finance.approval_chain ac
    WHERE ac.transaction_id = p_transaction_id
    
    UNION ALL
    
    -- Audit trail
    SELECT 
        'AUDIT_LOG'::VARCHAR,
        al.log_time,
        'Table: ' || al.table_name || ' Operation: ' || al.operation::TEXT,
        al.changed_by,
        'LOGGED'::VARCHAR
    FROM Finance.audit_logs al
    WHERE al.rec_transact LIKE '%"transaction_id":' || p_transaction_id::TEXT || '%'
    
    ORDER BY event_time DESC;
END;
$$ LANGUAGE plpgsql;

-- Get reconciliation report
DROP FUNCTION IF EXISTS Finance.get_reconciliation_report(INT, DATE, DATE) CASCADE;
CREATE FUNCTION Finance.get_reconciliation_report(
    p_client_id INT,
    p_from_date DATE,
    p_to_date DATE
)
RETURNS TABLE (
    account_name VARCHAR,
    reconciliation_date DATE,
    opening_balance DECIMAL,
    closing_balance DECIMAL,
    expected_balance DECIMAL,
    discrepancy_amount DECIMAL,
    status VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.account::VARCHAR,
        rt.reconciliation_date,
        rt.opening_balance,
        rt.closing_balance,
        rt.expected_balance,
        rt.discrepancy_amount,
        rt.status::VARCHAR
    FROM Finance.reconciliation_tracking rt
    JOIN Finance.charts c ON rt.account_id = c.chart_id
    WHERE rt.client_id = p_client_id
        AND rt.reconciliation_date BETWEEN p_from_date AND p_to_date
    ORDER BY rt.reconciliation_date DESC;
END;
$$ LANGUAGE plpgsql;

-- Get record lineage
DROP FUNCTION IF EXISTS Finance.get_record_lineage(VARCHAR, INT) CASCADE;
CREATE FUNCTION Finance.get_record_lineage(
    p_table_name VARCHAR,
    p_record_id INT
)
RETURNS TABLE (
    source_type VARCHAR,
    source_file VARCHAR,
    created_by VARCHAR,
    created_at TIMESTAMP,
    last_modified_by VARCHAR,
    last_modified_at TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        rl.source_type::VARCHAR,
        rl.source_file::VARCHAR,
        rl.created_by::VARCHAR,
        rl.created_at,
        rl.last_modified_by::VARCHAR,
        rl.last_modified_at
    FROM Finance.record_lineage rl
    WHERE rl.table_name = p_table_name AND rl.record_id = p_record_id;
END;
$$ LANGUAGE plpgsql;

