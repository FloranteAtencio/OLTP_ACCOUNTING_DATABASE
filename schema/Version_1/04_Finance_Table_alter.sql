-- ======================
-- 04 Table alters
-- 
-- ======================
BEGIN;

ALTER TABLE Finance.warehouses ADD COLUMN client_id INT NOT NULL REFERENCES Finance.clients(client_id) ON DELETE CASCADE;
ALTER TABLE Finance.operations ADD COLUMN client_id INT NOT NULL REFERENCES Finance.clients(client_id) ON DELETE CASCADE;
ALTER TABLE Finance.vendors ALTER COLUMN client_id SET NOT NULL;
ALTER TABLE Finance.customers ALTER COLUMN client_id SET NOT NULL;
ALTER TABLE Finance.inventory_audits ALTER COLUMN client_id SET NOT NULL;
ALTER TABLE Finance.products ADD COLUMN client_id INT NOT NULL REFERENCES Finance.clients(client_id) ON DELETE CASCADE;

-- Add created_at timestamps
ALTER TABLE Finance.customers ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE Finance.vendors ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE Finance.warehouses ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE Finance.products ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Add client settings
ALTER TABLE Finance.clients 
    ADD COLUMN inventory_method VARCHAR(20) CHECK (inventory_method IN ('PERPETUAL','PERIODIC')),
    ADD COLUMN inventory_cost_method VARCHAR(20) CHECK (inventory_cost_method IN ('FIFO','LIFO','AVCO'));

COMMIT;

SELECT '04 Finance Schema Table alter complete!' as  Status;
