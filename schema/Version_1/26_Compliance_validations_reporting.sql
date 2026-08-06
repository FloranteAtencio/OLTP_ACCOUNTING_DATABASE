BEGIN;

-- ============================================
-- 4. VALIDATION REPORTING
-- ============================================

-- Get validation summary
DROP FUNCTION IF EXISTS Compliance.get_validation_summary(INT) CASCADE;
CREATE FUNCTION Compliance.get_validation_summary(p_session_id INT)
RETURNS TABLE (
    total_rows INT,
    valid_rows INT,
    invalid_rows INT,
    warning_rows INT,
    validation_pass_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INT,
        COUNT(*) FILTER (WHERE is_valid = TRUE)::INT,
        COUNT(*) FILTER (WHERE is_valid = FALSE)::INT,
        COUNT(*) FILTER (WHERE severity = 'WARNING')::INT,
        ROUND((COUNT(*) FILTER (WHERE is_valid = TRUE)::NUMERIC / COUNT(*) * 100), 2)
    FROM Finance.import_validation_log
    WHERE session_id = p_session_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;

COMMIT;

SELECT '26 Compliance validation reporting' AS STATUS;