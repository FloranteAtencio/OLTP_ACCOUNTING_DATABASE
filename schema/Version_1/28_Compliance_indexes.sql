BEGIN;

CREATE INDEX idx_import_validation_session ON Audit.import_validation_log(session_id);
CREATE INDEX idx_import_validation_field ON Audit.import_validation_log(field_name);

CREATE INDEX idx_compliance_client ON Compliance.compliance_logs(client_id);
CREATE INDEX idx_compliance_status ON Compliance.compliance_logs(status);
-- CREATE INDEX idx_compliance_rule ON Compliance.compliance_logs(compliance_rule);

COMMIT;

SELECT '28 Compliance indexes' AS STATUS;