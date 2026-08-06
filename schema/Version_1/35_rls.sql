-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- Version: 2.0
-- Purpose: Ensure users only see data for their client/organization
-- ============================================

BEGIN;

-- Enable RLS enforcement on core tables
ALTER TABLE Finance.clients FORCE ROW LEVEL SECURITY;
ALTER TABLE Finance.charts FORCE ROW LEVEL SECURITY;
ALTER TABLE Finance.transactions FORCE ROW LEVEL SECURITY;
ALTER TABLE Finance.journals FORCE ROW LEVEL SECURITY;
ALTER TABLE Finance.account_receivables FORCE ROW LEVEL SECURITY;
ALTER TABLE Finance.account_payables FORCE ROW LEVEL SECURITY;
ALTER TABLE Finance.ar_ext FORCE ROW LEVEL SECURITY;
ALTER TABLE Finance.ap_ext FORCE ROW LEVEL SECURITY;
ALTER TABLE Finance.customers FORCE ROW LEVEL SECURITY;
ALTER TABLE Finance.vendors FORCE ROW LEVEL SECURITY;
ALTER TABLE Finance.inventory_audits FORCE ROW LEVEL SECURITY;
ALTER TABLE Finance.account_roles FORCE ROW LEVEL SECURITY;
ALTER TABLE Finance.account_properties FORCE ROW LEVEL SECURITY;

-- Enable RLS on audit tables
ALTER TABLE Audit.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE Audit.transaction_lifecycle ENABLE ROW LEVEL SECURITY;
ALTER TABLE Audit.approval_chain ENABLE ROW LEVEL SECURITY;
ALTER TABLE Audit.reconciliation_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE Audit.record_lineage ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION Finance.get_current_client_id()
RETURNS INT AS $$
BEGIN
    IF current_setting('app.current_client_id', true) IS NULL THEN
        RAISE EXCEPTION
            'Client context not set';
    END IF;

    RETURN current_setting('app.current_client_id')::INT;

END;
$$ LANGUAGE plpgsql STABLE;

-- Policy 1: Clients can only SELECT their own record
CREATE POLICY clients_select_own ON Finance.clients
    FOR SELECT
    USING (client_id = Finance.get_current_client_id());

-- Policy 2: Clients can only UPDATE their own record
CREATE POLICY clients_update_own ON Finance.clients
    FOR UPDATE
    USING (client_id = Finance.get_current_client_id())
    WITH CHECK (client_id = Finance.get_current_client_id());

-- SELECT only charts for current client
CREATE POLICY charts_select_by_client ON Finance.charts
    FOR SELECT
    USING (client_id = Finance.get_current_client_id());

-- INSERT only for current client
CREATE POLICY charts_insert_for_client ON Finance.charts
    FOR INSERT
    WITH CHECK (client_id = Finance.get_current_client_id());

-- UPDATE only for current client
CREATE POLICY charts_update_own_client ON Finance.charts
    FOR UPDATE
    USING (client_id = Finance.get_current_client_id())
    WITH CHECK (client_id = Finance.get_current_client_id());

-- Account Roles
CREATE POLICY account_roles_select_by_client ON Finance.account_roles
    FOR SELECT
    USING (
        chart_id IN (
            SELECT chart_id FROM Finance.charts 
            WHERE client_id = Finance.get_current_client_id()
        )
    );

CREATE POLICY account_roles_insert_for_client ON Finance.account_roles
    FOR INSERT
    WITH CHECK (
        chart_id IN (
            SELECT chart_id FROM Finance.charts 
            WHERE client_id = Finance.get_current_client_id()
        )
    );

-- Account Properties (same pattern)
CREATE POLICY account_properties_select_by_client ON Finance.account_properties
    FOR SELECT
    USING (
        chart_id IN (
            SELECT chart_id FROM Finance.charts 
            WHERE client_id = Finance.get_current_client_id()
        )
    );

CREATE POLICY account_properties_insert_for_client ON Finance.account_properties
    FOR INSERT
    WITH CHECK (
        chart_id IN (
            SELECT chart_id FROM Finance.charts 
            WHERE client_id = Finance.get_current_client_id()
        )
    );

CREATE POLICY transactions_select_by_client ON Finance.transactions
    FOR SELECT
    USING (client_id = Finance.get_current_client_id());

CREATE POLICY transactions_insert_for_client ON Finance.transactions
    FOR INSERT
    WITH CHECK (client_id = Finance.get_current_client_id());

CREATE POLICY transactions_update_own_client ON Finance.transactions
    FOR UPDATE
    USING (client_id = Finance.get_current_client_id())
    WITH CHECK (client_id = Finance.get_current_client_id());

-- Journals visible only if their transaction belongs to user's client
CREATE POLICY journals_select_by_client ON Finance.journals
    FOR SELECT
    USING (
        transaction_id IN (
            SELECT transaction_id 
            FROM Finance.transactions 
            WHERE client_id = Finance.get_current_client_id()
        )
    );

CREATE POLICY journals_insert_for_client ON Finance.journals
    FOR INSERT
    WITH CHECK (
        transaction_id IN (
            SELECT transaction_id 
            FROM Finance.transactions 
            WHERE client_id = Finance.get_current_client_id()
        )
    );

-- AR - Receivables
CREATE POLICY ar_select_by_client ON Finance.account_receivables
    FOR SELECT
    USING (
        transaction_id IN (
            SELECT transaction_id 
            FROM Finance.transactions 
            WHERE client_id = Finance.get_current_client_id()
        )
    );

CREATE POLICY ar_insert_for_client ON Finance.account_receivables
    FOR INSERT
    WITH CHECK (
        transaction_id IN (
            SELECT transaction_id 
            FROM Finance.transactions 
            WHERE client_id = Finance.get_current_client_id()
        )
    );

-- AP - Payables (same pattern)
CREATE POLICY ap_select_by_client ON Finance.account_payables
    FOR SELECT
    USING (
        transaction_id IN (
            SELECT transaction_id 
            FROM Finance.transactions 
            WHERE client_id = Finance.get_current_client_id()
        )
    );

CREATE POLICY ap_insert_for_client ON Finance.account_payables
    FOR INSERT
    WITH CHECK (
        transaction_id IN (
            SELECT transaction_id 
            FROM Finance.transactions 
            WHERE client_id = Finance.get_current_client_id()
        )
    );    

-- AR Extensions
CREATE POLICY ar_ext_select_by_client ON Finance.ar_ext
    FOR SELECT
    USING (
        receivable_id IN (
            SELECT receivable_id 
            FROM Finance.account_receivables ar
            WHERE ar.transaction_id IN (
                SELECT transaction_id 
                FROM Finance.transactions 
                WHERE client_id = Finance.get_current_client_id()
            )
        )
    );

-- AP Extensions
CREATE POLICY ap_ext_select_by_client ON Finance.ap_ext
    FOR SELECT
    USING (
        payable_id IN (
            SELECT payable_id 
            FROM Finance.account_payables ap
            WHERE ap.transaction_id IN (
                SELECT transaction_id 
                FROM Finance.transactions 
                WHERE client_id = Finance.get_current_client_id()
            )
        )
    );

-- Customers
CREATE POLICY customers_select_by_client ON Finance.customers
    FOR SELECT
    USING (client_id = Finance.get_current_client_id());

CREATE POLICY customers_insert_for_client ON Finance.customers
    FOR INSERT
    WITH CHECK (client_id = Finance.get_current_client_id());

-- Vendors
CREATE POLICY vendors_select_by_client ON Finance.vendors
    FOR SELECT
    USING (client_id = Finance.get_current_client_id());

CREATE POLICY vendors_insert_for_client ON Finance.vendors
    FOR INSERT
    WITH CHECK (client_id = Finance.get_current_client_id());    

CREATE POLICY inventory_audits_select_by_client ON Finance.inventory_audits
    FOR SELECT
    USING (
        transaction_id IN (
            SELECT transaction_id 
            FROM Finance.transactions 
            WHERE client_id = Finance.get_current_client_id()
        )
    );
-- Audit Logs (allow all)
CREATE POLICY audit_logs_select_auditors ON Audit.audit_logs
    FOR SELECT
    USING (true);  -- Auditors see everything

-- Transaction Lifecycle
CREATE POLICY transaction_lifecycle_select_by_client ON Audit.transaction_lifecycle
    FOR SELECT
    USING (client_id = Finance.get_current_client_id());

-- Approval Chain
CREATE POLICY approval_chain_select_by_client ON Audit.approval_chain
    FOR SELECT
    USING (client_id = Finance.get_current_client_id());

-- Reconciliation Tracking
CREATE POLICY reconciliation_tracking_select_by_client ON Audit.reconciliation_tracking
    FOR SELECT
    USING (client_id = Finance.get_current_client_id());

-- Record Lineage
CREATE POLICY record_lineage_select_by_client ON Audit.record_lineage
    FOR SELECT
    USING (
        COALESCE(client_id, Finance.get_current_client_id()) = Finance.get_current_client_id()
    );

-- ============================================
-- MISSING: INSERT, UPDATE, DELETE for ar_ext
-- ============================================

CREATE POLICY ar_ext_insert_for_client ON Finance.ar_ext
    FOR INSERT
    WITH CHECK (
        receivable_id IN (
            SELECT receivable_id FROM Finance.account_receivables ar
            WHERE ar.transaction_id IN (
                SELECT transaction_id FROM Finance.transactions 
                WHERE client_id = Finance.get_current_client_id()
            )
        )
    );

CREATE POLICY ar_ext_update_own_client ON Finance.ar_ext
    FOR UPDATE
    USING (
        receivable_id IN (
            SELECT receivable_id FROM Finance.account_receivables ar
            WHERE ar.transaction_id IN (
                SELECT transaction_id FROM Finance.transactions 
                WHERE client_id = Finance.get_current_client_id()
            )
        )
    )
    WITH CHECK (
        receivable_id IN (
            SELECT receivable_id FROM Finance.account_receivables ar
            WHERE ar.transaction_id IN (
                SELECT transaction_id FROM Finance.transactions 
                WHERE client_id = Finance.get_current_client_id()
            )
        )
    );

CREATE POLICY ar_ext_delete_own_client ON Finance.ar_ext
    FOR DELETE
    USING (
        receivable_id IN (
            SELECT receivable_id FROM Finance.account_receivables ar
            WHERE ar.transaction_id IN (
                SELECT transaction_id FROM Finance.transactions 
                WHERE client_id = Finance.get_current_client_id()
            )
        )
    );

-- ============================================
-- MISSING: INSERT, UPDATE, DELETE for ap_ext
-- ============================================

CREATE POLICY ap_ext_insert_for_client ON Finance.ap_ext
    FOR INSERT
    WITH CHECK (
        payable_id IN (
            SELECT payable_id FROM Finance.account_payables ap
            WHERE ap.transaction_id IN (
                SELECT transaction_id FROM Finance.transactions 
                WHERE client_id = Finance.get_current_client_id()
            )
        )
    );

CREATE POLICY ap_ext_update_own_client ON Finance.ap_ext
    FOR UPDATE
    USING (
        payable_id IN (
            SELECT payable_id FROM Finance.account_payables ap
            WHERE ap.transaction_id IN (
                SELECT transaction_id FROM Finance.transactions 
                WHERE client_id = Finance.get_current_client_id()
            )
        )
    )
    WITH CHECK (
        payable_id IN (
            SELECT payable_id FROM Finance.account_payables ap
            WHERE ap.transaction_id IN (
                SELECT transaction_id FROM Finance.transactions 
                WHERE client_id = Finance.get_current_client_id()
            )
        )
    );

CREATE POLICY ap_ext_delete_own_client ON Finance.ap_ext
    FOR DELETE
    USING (
        payable_id IN (
            SELECT payable_id FROM Finance.account_payables ap
            WHERE ap.transaction_id IN (
                SELECT transaction_id FROM Finance.transactions 
                WHERE client_id = Finance.get_current_client_id()
            )
        )
    );

-- ============================================
-- MISSING: UPDATE, DELETE for journals
-- ============================================

CREATE POLICY journals_update_own_client ON Finance.journals
    FOR UPDATE
    USING (
        transaction_id IN (
            SELECT transaction_id FROM Finance.transactions 
            WHERE client_id = Finance.get_current_client_id()
        )
    )
    WITH CHECK (
        transaction_id IN (
            SELECT transaction_id FROM Finance.transactions 
            WHERE client_id = Finance.get_current_client_id()
        )
    );

CREATE POLICY journals_delete_own_client ON Finance.journals
    FOR DELETE
    USING (
        transaction_id IN (
            SELECT transaction_id FROM Finance.transactions 
            WHERE client_id = Finance.get_current_client_id()
        )
    );

-- ============================================
-- MISSING: UPDATE, DELETE for account_receivables
-- ============================================

CREATE POLICY ar_update_own_client ON Finance.account_receivables
    FOR UPDATE
    USING (
        transaction_id IN (
            SELECT transaction_id FROM Finance.transactions 
            WHERE client_id = Finance.get_current_client_id()
        )
    )
    WITH CHECK (
        transaction_id IN (
            SELECT transaction_id FROM Finance.transactions 
            WHERE client_id = Finance.get_current_client_id()
        )
    );

CREATE POLICY ar_delete_own_client ON Finance.account_receivables
    FOR DELETE
    USING (
        transaction_id IN (
            SELECT transaction_id FROM Finance.transactions 
            WHERE client_id = Finance.get_current_client_id()
        )
    );

-- ============================================
-- MISSING: UPDATE, DELETE for account_payables
-- ============================================

CREATE POLICY ap_update_own_client ON Finance.account_payables
    FOR UPDATE
    USING (
        transaction_id IN (
            SELECT transaction_id FROM Finance.transactions 
            WHERE client_id = Finance.get_current_client_id()
        )
    )
    WITH CHECK (
        transaction_id IN (
            SELECT transaction_id FROM Finance.transactions 
            WHERE client_id = Finance.get_current_client_id()
        )
    );

CREATE POLICY ap_delete_own_client ON Finance.account_payables
    FOR DELETE
    USING (
        transaction_id IN (
            SELECT transaction_id FROM Finance.transactions 
            WHERE client_id = Finance.get_current_client_id()
        )
    );

-- ============================================
-- MISSING: UPDATE, DELETE for customers
-- ============================================

CREATE POLICY customers_update_own_client ON Finance.customers
    FOR UPDATE
    USING (client_id = Finance.get_current_client_id())
    WITH CHECK (client_id = Finance.get_current_client_id());

CREATE POLICY customers_delete_own_client ON Finance.customers
    FOR DELETE
    USING (client_id = Finance.get_current_client_id());

-- ============================================
-- MISSING: UPDATE, DELETE for vendors
-- ============================================

CREATE POLICY vendors_update_own_client ON Finance.vendors
    FOR UPDATE
    USING (client_id = Finance.get_current_client_id())
    WITH CHECK (client_id = Finance.get_current_client_id());

CREATE POLICY vendors_delete_own_client ON Finance.vendors
    FOR DELETE
    USING (client_id = Finance.get_current_client_id());

-- ============================================
-- MISSING: UPDATE, DELETE for clients
-- ============================================

CREATE POLICY clients_delete_own ON Finance.clients
    FOR DELETE
    USING (client_id = Finance.get_current_client_id());

-- ============================================
-- MISSING: INSERT, UPDATE, DELETE for inventory_audits
-- ============================================

CREATE POLICY inventory_audits_insert_for_client ON Finance.inventory_audits
    FOR INSERT
    WITH CHECK (
        transaction_id IN (
            SELECT transaction_id FROM Finance.transactions 
            WHERE client_id = Finance.get_current_client_id()
        )
    );

CREATE POLICY inventory_audits_update_own_client ON Finance.inventory_audits
    FOR UPDATE
    USING (
        transaction_id IN (
            SELECT transaction_id FROM Finance.transactions 
            WHERE client_id = Finance.get_current_client_id()
        )
    )
    WITH CHECK (
        transaction_id IN (
            SELECT transaction_id FROM Finance.transactions 
            WHERE client_id = Finance.get_current_client_id()
        )
    );

CREATE POLICY inventory_audits_delete_own_client ON Finance.inventory_audits
    FOR DELETE
    USING (
        transaction_id IN (
            SELECT transaction_id FROM Finance.transactions 
            WHERE client_id = Finance.get_current_client_id()
        )
    );

-- ==============================================================
-- Products Insert, update and delete policy
-- ==============================================================


CREATE POLICY products_SELECT_policy ON Finance.products
    FOR SELECT
        USING(client_id = Finance.get_current_client_id());

CREATE POLICY products_INSERT_policy ON Finance.products
    FOR INSERT
        WITH CHECK(client_id = Finance.get_current_client_id()
        );
    
CREATE POLICY products_DELETE_policy ON Finance.products
    FOR DELETE 
        USING (client_id = Finance.get_current_client_id());

CREATE POLICY products_UPDATE_policy ON Finance.products
    FOR UPDATE
        USING(client_id = Finance.get_current_client_id())
        WITH CHECK (client_id = Finance.get_current_client_id());

CREATE POLICY operation_select_products ON Finance.operations 
    FOR SELECT
        USING (
            product_id IN (
                SELECT product_id FROM Finance.products 
                WHERE client_id = Finance.get_current_client_id()
            )
        );

CREATE POLICY operation_insert_products ON Finance.operations 
    FOR INSERT
        WITH CHECK(
            product_id IN (
                SELECT product_id FROM Finance.products 
                WHERE client_id = Finance.get_current_client_id()
            )
        );

CREATE POLICY operation_delete_products ON Finance.operations 
    FOR DELETE
        USING(
            product_id IN (
                SELECT product_id FROM Finance.products 
                WHERE client_id = client_id = Finance.get_current_client_id()
            )
        );

CREATE POLICY operation_update_products ON Finance.operations
    FOR UPDATE
        USING(
            product_id IN (
                SELECT product_id FROM Finance.products
                WHERE client_id = get_current_client_id()
            )
        )
        WITH CHECK(
            product_id IN (
                SELECT product_id FROM Finance.products
                WHERE client_id = get_current_client_id()
            )
        );

CREATE POLICY warehouses_select_policy ON Finance.warehouses
    FOR SELECT
        USING(client_id = get_current_client_id());

CREATE POLICY warehouses_insert_policy ON Finance.warehouses
    FOR INSERT
        WITH CHECK (client_id = get_current_client_id());

CREATE POLICY warehouses_delete_policy ON Finance.warehouses
    FOR DELETE
        USING(client_id = get_current_client_id());

CREATE POLICY warehouses_update_policy ON Finance.warehouses
    FOR UPDATE
        USING(client_id = get_current_client_id())
        WITH CHECK(client_id = get_current_client_id());            
-- -- ============================================
-- -- MISSING: Tax table policies
-- -- ============================================

-- CREATE POLICY tax_types_update_own_client ON Finance.tax_types
--     FOR UPDATE
--     USING (client_id = Finance.get_current_client_id())
--     WITH CHECK (client_id = Finance.get_current_client_id());

-- CREATE POLICY tax_types_delete_own_client ON Finance.tax_types
--     FOR DELETE
--     USING (client_id = Finance.get_current_client_id());

-- CREATE POLICY tax_calculations_update_own_client ON Finance.tax_calculations
--     FOR UPDATE
--     USING (client_id = Finance.get_current_client_id())
--     WITH CHECK (client_id = Finance.get_current_client_id());

-- CREATE POLICY tax_calculations_delete_own_client ON Finance.tax_calculations
--     FOR DELETE
--     USING (client_id = Finance.get_current_client_id());

-- CREATE POLICY tax_liabilities_update_own_client ON Finance.tax_liabilities
--     FOR UPDATE
--     USING (client_id = Finance.get_current_client_id())
--     WITH CHECK (client_id = Finance.get_current_client_id());

-- CREATE POLICY tax_liabilities_delete_own_client ON Finance.tax_liabilities
--     FOR DELETE
--     USING (client_id = Finance.get_current_client_id());



COMMIT;    
-- -- ============================================
-- -- PREREQUISITE: Enable RLS on tables
-- -- ============================================

-- ALTER TABLE finance.clients ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE finance.charts ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE finance.transactions ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE finance.journals ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE finance.account_receivables ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE finance.account_payables ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE finance.ar_ext ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE finance.ap_ext ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE finance.customers ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE finance.vendors ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE finance.inventory_audits ENABLE ROW LEVEL SECURITY;

-- CREATE OR REPLACE FUNCTION Finance.get_current_client_id()
-- RETURNS INT AS $$
-- BEGIN
--     RETURN COALESCE(
--         (current_setting('app.current_client_id', true))::INT,
--         1  -- Default to client 1 if not set
--     );
-- END;
-- $$ LANGUAGE plpgsql IMMUTABLE;

-- -- ============================================
-- -- 1. HELPER FUNCTION: Get current client_id
-- -- ============================================

-- CREATE OR REPLACE FUNCTION finance.get_current_client_id()
-- RETURNS INT AS $$
-- BEGIN
--     RETURN COALESCE(
--         (current_setting('app.current_client_id', true))::INT,
--         1  -- Default to client 1 if not set
--     );
-- END;
-- $$ LANGUAGE plpgsql IMMUTABLE;

-- -- ============================================
-- -- 2. CLIENT TABLE RLS
-- -- ============================================

-- -- Clients can only see their own record
-- CREATE POLICY clients_select_own ON finance.clients
--     FOR SELECT
--     USING (client_id = finance.get_current_client_id());

-- CREATE POLICY clients_update_own ON finance.clients
--     FOR UPDATE
--     USING (client_id = finance.get_current_client_id())
--     WITH CHECK (client_id = finance.get_current_client_id());

-- -- ============================================
-- -- 3. CHART OF ACCOUNTS RLS
-- -- ============================================

-- -- Users see only charts for their assigned client
-- CREATE POLICY charts_select_by_client ON finance.charts
--     FOR SELECT
--     USING (client_id = finance.get_current_client_id());

-- CREATE POLICY charts_insert_for_client ON finance.charts
--     FOR INSERT
--     WITH CHECK (client_id = finance.get_current_client_id());

-- CREATE POLICY charts_update_own_client ON finance.charts
--     FOR UPDATE
--     USING (client_id = finance.get_current_client_id())
--     WITH CHECK (client_id = finance.get_current_client_id());

-- -- ============================================
-- -- 4. TRANSACTIONS RLS
-- -- ============================================

-- -- Transactions filtered by client
-- CREATE POLICY transactions_select_by_client ON finance.transactions
--     FOR SELECT
--     USING (client_id = finance.get_current_client_id());

-- CREATE POLICY transactions_insert_for_client ON finance.transactions
--     FOR INSERT
--     WITH CHECK (client_id = finance.get_current_client_id());

-- CREATE POLICY transactions_update_own_client ON finance.transactions
--     FOR UPDATE
--     USING (client_id = finance.get_current_client_id())
--     WITH CHECK (client_id = finance.get_current_client_id());

-- -- ============================================
-- -- 5. JOURNALS RLS (via transaction.client_id)
-- -- ============================================

-- -- Journals visible only if related transaction belongs to user's client
-- CREATE POLICY journals_select_by_client ON finance.journals
--     FOR SELECT
--     USING (
--         transaction_id IN (
--             SELECT transaction_id 
--             FROM finance.transactions 
--             WHERE client_id = finance.get_current_client_id()
--         )
--     );

-- CREATE POLICY journals_insert_for_client ON finance.journals
--     FOR INSERT
--     WITH CHECK (
--         transaction_id IN (
--             SELECT transaction_id 
--             FROM finance.transactions 
--             WHERE client_id = finance.get_current_client_id()
--         )
--     );

-- -- ============================================
-- -- 6. ACCOUNTS RECEIVABLE RLS
-- -- ============================================

-- CREATE POLICY ar_select_by_client ON finance.account_receivables
--     FOR SELECT
--     USING (
--         transaction_id IN (
--             SELECT transaction_id 
--             FROM finance.transactions 
--             WHERE client_id = finance.get_current_client_id()
--         )
--     );

-- CREATE POLICY ar_insert_for_client ON finance.account_receivables
--     FOR INSERT
--     WITH CHECK (
--         transaction_id IN (
--             SELECT transaction_id 
--             FROM finance.transactions 
--             WHERE client_id = finance.get_current_client_id()
--         )
--     );

-- -- ============================================
-- -- 7. ACCOUNTS PAYABLE RLS
-- -- ============================================

-- CREATE POLICY ap_select_by_client ON finance.account_payables
--     FOR SELECT
--     USING (
--         transaction_id IN (
--             SELECT transaction_id 
--             FROM finance.transactions 
--             WHERE client_id = finance.get_current_client_id()
--         )
--     );

-- CREATE POLICY ap_insert_for_client ON finance.account_payables
--     FOR INSERT
--     WITH CHECK (
--         transaction_id IN (
--             SELECT transaction_id 
--             FROM finance.transactions 
--             WHERE client_id = finance.get_current_client_id()
--         )
--     );

-- -- ============================================
-- -- 8. AR/AP EXTENSIONS RLS
-- -- ============================================

-- CREATE POLICY ar_ext_select_by_client ON finance.ar_ext
--     FOR SELECT
--     USING (
--         receivable_id IN (
--             SELECT ar.receivable_id 
--             FROM finance.account_receivables ar
--             WHERE ar.transaction_id IN (
--                 SELECT transaction_id 
--                 FROM finance.transactions 
--                 WHERE client_id = finance.get_current_client_id()
--             )
--         )
--     );

-- CREATE POLICY ap_ext_select_by_client ON finance.ap_ext
--     FOR SELECT
--     USING (
--         payable_id IN (
--             SELECT ap.payable_id 
--             FROM finance.account_payables ap
--             WHERE ap.transaction_id IN (
--                 SELECT transaction_id 
--                 FROM finance.transactions 
--                 WHERE client_id = finance.get_current_client_id()
--             )
--         )
--     );

-- -- ============================================
-- -- 9. CUSTOMERS RLS
-- -- ============================================

-- -- Assuming customers have client relationship
-- -- If not, add client_id column to customers table
-- CREATE POLICY customers_select_any ON finance.customers
--     FOR SELECT
--     USING (true);  -- Adjust based on your customer model

-- -- ============================================
-- -- 10. VENDORS/SUPPLIERS RLS
-- -- ============================================

-- CREATE POLICY vendors_select_any ON finance.vendors
--     FOR SELECT
--     USING (true);  -- Adjust based on your vendor model

-- -- ============================================
-- -- 11. INVENTORY AUDITS RLS
-- -- ============================================

-- CREATE POLICY inventory_audits_select_by_client ON finance.inventory_audits
--     FOR SELECT
--     USING (
--         transaction_id IN (
--             SELECT transaction_id 
--             FROM finance.transactions 
--             WHERE client_id = finance.get_current_client_id()
--         )
--     );

-- -- ============================================
-- -- ENABLE RLS ENFORCEMENT
-- -- ============================================

-- ALTER TABLE finance.audit_logs ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY audit_logs_select_auditors ON finance.audit_logs
--     FOR SELECT
--     USING (true);  -- Auditors can see all audit logs

-- COMMIT;

-- -- ============================================
-- -- USAGE EXAMPLES
-- -- ============================================

-- -- To set client context before queries:
-- -- SET app.current_client_id = '1';
-- -- SELECT * FROM finance.transactions;  -- Only returns transactions for client 1

-- -- To reset:
-- -- RESET app.current_client_id;
