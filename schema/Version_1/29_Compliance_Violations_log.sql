BEGIN;

-- Get compliance violations
DROP FUNCTION IF EXISTS Compliance.get_compliance_violations(INT, INT) CASCADE;
CREATE FUNCTION Compliance.get_compliance_violations(
    p_client_id INT,
    p_days INT DEFAULT 30
)
RETURNS TABLE (
    compliance_id BIGINT,
    rule_name VARCHAR,
    check_type VARCHAR,
    status VARCHAR,
    details TEXT,
    checked_at TIMESTAMP,
    resolution_status VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cl.compliance_id,
        cl.compliance_rule::VARCHAR,
        cl.check_type::VARCHAR,
        cl.status::VARCHAR,
        cl.details::TEXT,
        cl.checked_at,
        COALESCE(cl.resolution_status, 'UNRESOLVED')::VARCHAR
    FROM Compliance.compliance_logs cl
    WHERE cl.client_id = p_client_id
        AND cl.status != 'PASS'
        AND cl.checked_at >= CURRENT_TIMESTAMP - (p_days || ' days')::INTERVAL
    ORDER BY cl.checked_at DESC;
END;
$$ LANGUAGE plpgsql;

COMMIT;

SELECT '29 Compliance violations log' AS STATUS;