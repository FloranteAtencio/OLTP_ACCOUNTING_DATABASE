BEGIN;

CREATE INDEX idx_audit_logs_extended_client ON Audit.audit_logs_extended(client_id);
CREATE INDEX idx_audit_logs_extended_time ON Audit.audit_logs_extended(changed_at);
CREATE INDEX idx_audit_logs_extended_user ON Audit.audit_logs_extended(changed_by);
CREATE INDEX idx_audit_logs_extended_record ON Audit.audit_logs_extended(table_name, record_id);

CREATE INDEX idx_import_sessions_client ON Audit.import_sessions(client_id);
CREATE INDEX idx_import_sessions_status ON Audit.import_sessions(status);
CREATE INDEX idx_import_sessions_date ON Audit.import_sessions(started_at);

CREATE INDEX idx_import_detail_session ON Audit.import_detail_logs(session_id);
CREATE INDEX idx_import_detail_status ON Audit.import_detail_logs(status);
CREATE INDEX idx_import_detail_table ON Audit.import_detail_logs(table_name);

CREATE INDEX idx_transaction_lifecycle_id ON Audit.transaction_lifecycle(transaction_id);
CREATE INDEX idx_transaction_lifecycle_client ON Audit.transaction_lifecycle(client_id);
CREATE INDEX idx_transaction_lifecycle_state ON Audit.transaction_lifecycle(new_state);
CREATE INDEX idx_transaction_lifecycle_time ON Audit.transaction_lifecycle(changed_at);

CREATE INDEX idx_approval_chain_transaction ON Audit.approval_chain(transaction_id);
CREATE INDEX idx_approval_chain_status ON Audit.approval_chain(status);

CREATE INDEX idx_reconciliation_account ON Audit.reconciliation_tracking(account_id);
CREATE INDEX idx_reconciliation_date ON Audit.reconciliation_tracking(reconciliation_date);
CREATE INDEX idx_reconciliation_status ON Audit.reconciliation_tracking(status);

CREATE INDEX idx_record_lineage_table ON Audit.record_lineage(table_name, record_id);
CREATE INDEX idx_record_lineage_source ON Audit.record_lineage(source_type);
CREATE INDEX idx_record_lineage_session ON Audit.record_lineage(import_session_id);

COMMIT;

SELECT 'Audit Schema indexs Complete' as Status;