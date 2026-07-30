
CREATE INDEX idx_import_validation_session ON Compliance.import_validation_log(session_id);
CREATE INDEX idx_import_validation_field ON Compliance.import_validation_log(field_name);

CREATE INDEX idx_compliance_client ON Compliance.compliance_log(client_id);
CREATE INDEX idx_compliance_status ON Compliance.compliance_log(status);
CREATE INDEX idx_compliance_rule ON Compliance.compliance_log(compliance_rule);
