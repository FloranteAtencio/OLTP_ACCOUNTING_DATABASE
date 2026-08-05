BEGIN;

CREATE SCHEMA Compliance;
-- ============================================================
-- compliance schema log
-- ============================================================
DROP TABLE IF EXISTS Compliance.compliance_rules CASCADE; -- Renamed to 'rules' for clarity
CREATE TABLE Compliance.compliance_rules (
    rule_id INT PRIMARY KEY, -- Or BIGSERIAL if you want auto-increment
    rule_name VARCHAR(100) NOT NULL UNIQUE, -- e.g., 'Positive Amount Rule'
    check_type VARCHAR(50) NOT NULL CHECK (check_type IN (
        'BALANCE_CHECK', 'AMOUNT_CHECK', 'DATE_CHECK', 'CLIENT_CHECK','CUSTOMER_CHECK','DUPLICATE_CHECK', 'THRESHOLD_CHECK', 'RECONCILIATION_CHECK','STATUS_CHECK'
        )),   
    description TEXT, -- e.g., 'Ensures AR amount is strictly positive'
    severity VARCHAR(20) DEFAULT 'ERROR', -- 'WARNING', 'ERROR', 'CRITICAL'
    is_active BOOLEAN DEFAULT TRUE -- To disable a rule without deleting history
);

-- Seed some data
INSERT INTO Compliance.compliance_rules (rule_id, rule_name, check_type, description) VALUES
(1, 'Positive Amount Rule', 'AMOUNT_CHECK', 'Ensures AR amount is strictly positive'),
(2, 'Valid Date Range', 'DATE_CHECK', 'Invoice date must be before due date'),
(3, 'Customer Existence', 'CUSTOMER_CHECK', 'Customer ID must exist in Finance.customers'),
(4, 'Status Existence', 'STATUS_CHECK', 'Status should be at the given list');

-- ========================================
-- compliance schema Trails
-- =========================================
CREATE TABLE Compliance.compliance_logs (
    log_id BIGSERIAL PRIMARY KEY,
    client_id INT NOT NULL REFERENCES Finance.clients (client_id),
    -- The Rule
    rule_id INT NOT NULL REFERENCES Compliance.compliance_rules(rule_id),
    
    -- The Link to Data (Now Flexible)
    session_id INT,                   -- NULL if direct entry
    staging_record_id INT,         -- NULL if direct to production
    
    -- The Link to Production (NEW!)
    production_record_id INT,      -- The ID in the production table (if applicable)
    target_table_name VARCHAR(50),    -- e.g., 'accounts_receivable', 'journal_entries'
    
    -- The Result
    status VARCHAR(20) NOT NULL CHECK (status IN ('PASS', 'FAIL', 'WARNING')),
    notes TEXT,
    
    -- Resolution
    resolution_status VARCHAR(20) CHECK (resolution_status IN ('UNRESOLVED', 'RESOLVED', 'WAIVED')),
    resolved_by VARCHAR(100),
    resolved_at TIMESTAMP,
    
    -- Metadata
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    --actor_id VARCHAR(100)
);

-- Constraint: You must link to SOME data (Staging OR Production)
-- ALTER TABLE Compliance.compliance_logs
-- ADD CONSTRAINT chk_data_linkage 
-- CHECK (
--     (staging_record_id IS NOT NULL AND session_id IS NOT NULL) OR 
--     (production_record_id IS NOT NULL AND target_table_name IS NOT NULL)
-- );

-- If no record exists yet (e.g., pre-check), store the payload hash
ALTER TABLE Compliance.compliance_logs
ADD COLUMN payload_hash VARCHAR(64); -- SHA-256 hash of the data

-- Indexes for Performance (Crucial for lineage queries)
CREATE INDEX idx_compliance_logs_session ON Compliance.compliance_logs(session_id);
CREATE INDEX idx_compliance_logs_record ON Compliance.compliance_logs(staging_record_id);
CREATE INDEX idx_compliance_logs_rule ON Compliance.compliance_logs(rule_id);
COMMIT;

SELECT 'Compliance Schema Tables complete!' AS STATUS;