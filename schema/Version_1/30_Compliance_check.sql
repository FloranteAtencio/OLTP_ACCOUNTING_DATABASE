
-- Log compliance check
DROP FUNCTION IF EXISTS Audit.log_compliance_check(INT, VARCHAR, TEXT, VARCHAR, VARCHAR, TEXT) CASCADE;
CREATE FUNCTION Audit.log_compliance_check(
    p_client_id INT,
    p_rule_name VARCHAR,
    p_rule_description TEXT,
    p_check_type VARCHAR,
    p_status VARCHAR,
    p_details TEXT DEFAULT NULL
)
RETURNS BIGINT AS $$
DECLARE
    v_compliance_id BIGINT;
BEGIN
    INSERT INTO Compliance.compliance_log (
        client_id, compliance_rule, rule_description, check_type, status, details
    )
    VALUES (p_client_id, p_rule_name, p_rule_description, p_check_type, p_status, p_details)
    RETURNING compliance_id INTO v_compliance_id;
    
    RETURN v_compliance_id;
END;
$$ LANGUAGE plpgsql;