BEGIN;

-- Function to get import history for a client
DROP FUNCTION IF EXISTS Audit.get_import_history(INT, INT) CASCADE;
CREATE FUNCTION Audit.get_import_history(
    p_client_id INT,
    p_limit INT DEFAULT 50
)
RETURNS TABLE (
    session_id INT,
    import_type VARCHAR,
    imported_by VARCHAR,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    status VARCHAR,
    total_records INT,
    successful_records INT,
    failed_records INT,
    success_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.session_id,
        s.import_type,
        s.imported_by,
        s.started_at,
        s.completed_at,
        s.status,
        s.total_records,
        s.successful_records,
        s.failed_records,
        CASE WHEN s.total_records > 0 
             THEN ROUND((s.successful_records::NUMERIC / s.total_records * 100), 2)
             ELSE 0 END
    FROM Audit.import_sessions s
    WHERE s.client_id = p_client_id
    ORDER BY s.started_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Function to get failed imports
DROP FUNCTION IF EXISTS Audit.get_failed_imports(INT, INT) CASCADE;
CREATE FUNCTION Audit.get_failed_imports(
    p_client_id INT,
    p_limit INT DEFAULT 50
)
RETURNS TABLE (
    session_id INT,
    import_type VARCHAR,
    row_number INT,
    table_name VARCHAR,
    error_message TEXT,
    failed_at TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        idl.session_id,
        s.import_type,
        idl.row_number,
        idl.table_name,
        idl.error_message,
        idl.created_at
    FROM Audit.import_detail_logs idl
    JOIN Audit.import_sessions s ON idl.session_id = s.session_id
    WHERE s.client_id = p_client_id AND idl.status = 'FAILED'
    ORDER BY idl.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Function to get user audit trail
DROP FUNCTION IF EXISTS Audit.get_user_audit_trail(VARCHAR, INT) CASCADE;
CREATE FUNCTION Audit.get_user_audit_trail(
    p_username VARCHAR,
    p_days INT DEFAULT 30
)
RETURNS TABLE (
    audit_id INT,
    table_name VARCHAR,
    operation VARCHAR,
    record_id INT,
    old_value TEXT,
    new_value TEXT,
    changed_at TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ale.extended_audit_id::INT,
        ale.table_name,
        ale.operation,
        ale.record_id,
        ale.old_value,
        ale.new_value,
        ale.changed_at
    FROM Audit.audit_logs_extended ale
    WHERE ale.changed_by = p_username 
        AND ale.changed_at >= CURRENT_TIMESTAMP - (p_days || ' days')::INTERVAL
    ORDER BY ale.changed_at DESC;
END;
$$ LANGUAGE plpgsql;

COMMIT;

SELECT 'Audit Schema get report complete' as STATUS;