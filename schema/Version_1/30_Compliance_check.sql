CREATE OR REPLACE FUNCTION Compliance.import_validation(
    p_session_id INT,
    p_row_number INT,
    p_field_name VARCHAR,
    p_validation_rule VARCHAR,
    p_actual_value TEXT,
    p_is_valid BOOLEAN,
    p_severity VARCHAR
)
RETURNS BIGINT AS $$
DECLARE

    new_id BIGINT;

BEGIN

    INSERT INTO Compliance.import_validation_log(
        session_id
        ,row_number
        ,field_name
        ,validation_rule 
        ,actual_value 
        ,is_valid 
        ,severity -- 'ERROR', 'WARNING', 'INFO'
        
    )
    VALUES(
        p_session_id
        , p_row_number
        , p_field_name
        , p_validation_rule
        , actual_value
        , p_is_valid
        , p_severity
        
    )
    RETURNING validation_id INTO new_id;

    RETURN new_id;

END;
$$ LANGUAGE plpgsql;

-- Log compliance check
DROP FUNCTION IF EXISTS Compliance.log_compliance_check(INT, VARCHAR, TEXT, VARCHAR, VARCHAR, TEXT) CASCADE;
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
        client_id, 
        compliance_rule, 
        rule_description, 
        check_type, --'BALANCE_CHECK', 'AMOUNT_CHECK', 'DATE_CHECK', 'CLIENT_CHECK','CUSTOMER_CHECK','DUPLICATE_CHECK', 'THRESHOLD_CHECK', 'RECONCILIATION_CHECK'
        status, -- 'PASS', 'FAIL', 'WARNING'
        details -- NOTES
    )
    VALUES (p_client_id, p_rule_name, p_rule_description, p_check_type, p_status, p_details)
    RETURNING compliance_id INTO v_compliance_id;
    
    RETURN v_compliance_id;
END;
$$ LANGUAGE plpgsql;