-- Log compliance check
-- DROP FUNCTION IF EXISTS Compliance.log_compliance_check(INT, VARCHAR, TEXT, VARCHAR, VARCHAR, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION Compliance.log_compliance_check(
    p_client_id INT,
    p_rule_id INT,
    p_session_id INT,
    p_staging_record_id INT,
    p_production_record_id INT,
    p_target_table_name VARCHAR,
    p_status VARCHAR,
    p_resolution_status VARCHAR,
    p_notes TEXT
)
RETURNS BIGINT AS $$
DECLARE
    v_compliance_id BIGINT;
BEGIN
    INSERT INTO Compliance.compliance_logs (
        client_id, 
        rule_id, 
        session_id, 
        staging_record_id, --'BALANCE_CHECK', 'AMOUNT_CHECK', 'DATE_CHECK', 'CLIENT_CHECK','CUSTOMER_CHECK','DUPLICATE_CHECK', 'THRESHOLD_CHECK', 'RECONCILIATION_CHECK'
        production_record_id, -- 'PASS', 'FAIL', 'WARNING'
        target_table_name, -- NOTES
        status,
        resolution_status,
        notes
    )
    VALUES (
        p_client_id, 
        p_rule_id, 
        p_session_id, 
        p_staging_record_id, 
        p_production_record_id, 
        p_target_table_name,
        p_status,
        p_resolution_status,
        p_notes)
    RETURNING compliance_id INTO v_compliance_id;
    
    RETURN v_compliance_id;
END;
$$ LANGUAGE plpgsql;