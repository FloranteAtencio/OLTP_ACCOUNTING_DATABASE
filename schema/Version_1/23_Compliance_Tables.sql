BEGIN;

CREATE SCHEMA Compliance;
-- ============================================================
-- compliance schema to be transer later
-- ============================================================
DROP TABLE IF EXISTS Compliance.import_validation_log CASCADE;
CREATE TABLE Compliance.import_validation_log (
    validation_id BIGSERIAL PRIMARY KEY,
    session_id INT REFERENCES Audit.import_sessions(session_id) ON DELETE NO ACTION,
    row_number INT NOT NULL,
    field_name VARCHAR(255) NOT NULL,
    validation_rule VARCHAR(255) NOT NULL,
    expected_value TEXT,
    actual_value TEXT,
    is_valid BOOLEAN NOT NULL,
    severity VARCHAR(20) DEFAULT 'ERROR' CHECK (severity IN ('ERROR', 'WARNING', 'INFO')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS Compliance.compliance_log CASCADE;
CREATE TABLE Compliance.compliance_log (
    compliance_id BIGSERIAL PRIMARY KEY,
    client_id INT NOT NULL REFERENCES Finance.clients(client_id) ON DELETE NO ACTION,
    compliance_rule VARCHAR(255) NOT NULL,
    rule_description TEXT,
    check_type VARCHAR(50) NOT NULL CHECK (check_type IN (
        'BALANCE_CHECK', 'AMOUNT_CHECK', 'DATE_CHECK', 'CLIENT_CHECK','CUSTOMER_CHECK','DUPLICATE_CHECK', 'THRESHOLD_CHECK', 'RECONCILIATION_CHECK'
        )),
    status VARCHAR(20) NOT NULL CHECK (status IN ('PASS', 'FAIL', 'WARNING')),
    details TEXT,
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolution_status VARCHAR(20) CHECK (resolution_status IN ('UNRESOLVED', 'RESOLVED', 'WAIVED')),
    resolution_notes TEXT,
    resolved_at TIMESTAMP
);

COMMIT;

SELECT 'Compliance Schema Tables complete!' AS STATUS;