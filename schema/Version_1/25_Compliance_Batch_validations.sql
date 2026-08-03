-- Validate entire transaction
DROP FUNCTION IF EXISTS Compliance.validate_transaction_import(INT, INT, DECIMAL, DATE) CASCADE;
CREATE FUNCTION Compliance.validate_transaction_import(
    p_transaction_id INT,
    p_chart_id INT,
    p_amount DECIMAL,
    p_date DATE
)
RETURNS TABLE (is_valid BOOLEAN, errors TEXT) AS $$
DECLARE
    v_errors TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Validate amount
    IF p_amount < 0 THEN
        v_errors := array_append(v_errors, 'Amount cannot be negative');
    END IF;
    
    -- Validate date
    IF p_date > CURRENT_DATE THEN
        v_errors := array_append(v_errors, 'Transaction date cannot be in the future');
    END IF;
    
    -- Validate account exists
    IF NOT EXISTS (SELECT 1 FROM Finance.charts WHERE chart_id = p_chart_id AND is_active = TRUE) THEN
        v_errors := array_append(v_errors, 'Invalid chart/account ID');
    END IF;
    
    -- Validate transaction exists
    IF NOT EXISTS (SELECT 1 FROM Finance.transactions WHERE transaction_id = p_transaction_id) THEN
        v_errors := array_append(v_errors, 'Transaction ID does not exist');
    END IF;
    
    RETURN QUERY SELECT 
        CASE WHEN array_length(v_errors, 1) IS NULL THEN TRUE ELSE FALSE END,
        array_to_string(v_errors, '; ');
END;
$$ LANGUAGE plpgsql;

-- Validate AR import
DROP FUNCTION IF EXISTS Compliance.validate_ar_import(INT, INT, DECIMAL, DATE, DATE, VARCHAR) CASCADE;
CREATE FUNCTION Compliance.validate_ar_import(
    p_receivable_id INT,
    p_customer_id INT,
    p_amount DECIMAL,
    p_invoice_date DATE,
    p_due_date DATE,
    p_status VARCHAR
)
RETURNS TABLE (amount_error TEXT, Invoice_error TEXT, customer_error TEXT, status_error TEXT) AS $$
DECLARE

    v_errors_amount TEXT;
    v_errors_invoice TEXT;
    v_errors_customer TEXT;
    v_errors_status TEXT;
    
BEGIN
    -- Validate amount
    IF p_amount <= 0 THEN
        v_errors_1 := 'AR amount must be positive';
    END IF;
    
    -- Validate dates
    IF p_invoice_date > p_due_date THEN
        v_errors_2 := 'Invoice date cannot be after due date';
    END IF;
    
    -- Validate customer exists
    IF NOT EXISTS (SELECT 1 FROM Finance.customers WHERE customer_id = p_customer_id) THEN
        v_errors_3 := 'Customer ID does not exist';
    END IF;
    
    -- Validate status
    IF p_status NOT IN ('Pending', 'Partial', 'Paid', 'Overdue') THEN
        v_errors_4 := 'Invalid AR status';
    END IF;
    
    RETURN QUERY SELECT
        v_errors_amount,
        v_errors_invoice,
        v_errors_customer,
        v_errors_status;
END;
$$ LANGUAGE plpgsql;

-- Validate AP import
DROP FUNCTION IF EXISTS Compliance.validate_ap_import(INT, INT, DECIMAL, DATE, DATE, VARCHAR) CASCADE;
CREATE FUNCTION Compliance.validate_ap_import(
    p_payable_id INT,
    p_vendor_id INT,
    p_amount DECIMAL,
    p_invoice_date DATE,
    p_due_date DATE,
    p_status VARCHAR
)
RETURNS TABLE (is_valid BOOLEAN, errors TEXT) AS $$
DECLARE
    v_errors TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Validate amount
    IF p_amount <= 0 THEN
        v_errors := array_append(v_errors, 'AP amount must be positive');
    END IF;
    
    -- Validate dates
    IF p_invoice_date > p_due_date THEN
        v_errors := array_append(v_errors, 'Invoice date cannot be after due date');
    END IF;
    
    -- Validate vendor exists
    IF NOT EXISTS (SELECT 1 FROM Finance.vendors WHERE vendor_id = p_vendor_id) THEN
        v_errors := array_append(v_errors, 'Vendor ID does not exist');
    END IF;
    
    -- Validate status
    IF p_status NOT IN ('Pending', 'Partial', 'Paid', 'Overdue') THEN
        v_errors := array_append(v_errors, 'Invalid AP status');
    END IF;
    
    RETURN QUERY SELECT 
        CASE WHEN array_length(v_errors, 1) IS NULL THEN TRUE ELSE FALSE END,
        array_to_string(v_errors, '; ');
END;
$$ LANGUAGE plpgsql;

-- Validate inventory import
DROP FUNCTION IF EXISTS Compliance.validate_inventory_import(INT, INT, INT, INT, VARCHAR) CASCADE;
CREATE FUNCTION Compliance.validate_inventory_import(
    p_product_id INT,
    p_warehouse_id INT,
    p_quantity INT,
    p_transaction_id INT,
    p_action_type VARCHAR
)
RETURNS TABLE (is_valid BOOLEAN, errors TEXT) AS $$
DECLARE
    v_errors TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Validate quantity
    IF p_quantity <= 0 THEN
        v_errors := array_append(v_errors, 'Quantity must be greater than 0');
    END IF;
    
    -- Validate product exists
    IF NOT EXISTS (SELECT 1 FROM Finance.products WHERE product_id = p_product_id) THEN
        v_errors := array_append(v_errors, 'Product ID does not exist');
    END IF;
    
    -- Validate warehouse exists
    IF NOT EXISTS (SELECT 1 FROM Finance.warehouses WHERE warehouse_id = p_warehouse_id) THEN
        v_errors := array_append(v_errors, 'Warehouse ID does not exist');
    END IF;
    
    -- Validate action type
    IF p_action_type NOT IN ('Purchase', 'Sale', 'Sale Return', 'Purchase Return', 'Transfer') THEN
        v_errors := array_append(v_errors, 'Invalid inventory action type');
    END IF;
    
    -- Validate transaction exists
    IF NOT EXISTS (SELECT 1 FROM Finance.transactions WHERE transaction_id = p_transaction_id) THEN
        v_errors := array_append(v_errors, 'Transaction ID does not exist');
    END IF;
    
    RETURN QUERY SELECT 
        CASE WHEN array_length(v_errors, 1) IS NULL THEN TRUE ELSE FALSE END,
        array_to_string(v_errors, '; ');
END;
$$ LANGUAGE plpgsql;


-- =====================================================================================
-- Validate entire transaction PRESEVERVING CODE FOR FUTURE REFERENCE
-- =====================================================================================


-- DROP FUNCTION IF EXISTS Compliance.validate_transaction_import(INT, INT, DECIMAL, DATE) CASCADE;
-- CREATE FUNCTION Compliance.validate_transaction_import(
--     p_transaction_id INT,
--     p_chart_id INT,
--     p_amount DECIMAL,
--     p_date DATE
-- )
-- RETURNS TABLE (is_valid BOOLEAN, errors TEXT) AS $$
-- DECLARE
--     v_errors TEXT[] := ARRAY[]::TEXT[];
-- BEGIN
--     -- Validate amount
--     IF p_amount < 0 THEN
--         v_errors := array_append(v_errors, 'Amount cannot be negative');
--     END IF;
    
--     -- Validate date
--     IF p_date > CURRENT_DATE THEN
--         v_errors := array_append(v_errors, 'Transaction date cannot be in the future');
--     END IF;
    
--     -- Validate account exists
--     IF NOT EXISTS (SELECT 1 FROM Finance.charts WHERE chart_id = p_chart_id AND is_active = TRUE) THEN
--         v_errors := array_append(v_errors, 'Invalid chart/account ID');
--     END IF;
    
--     -- Validate transaction exists
--     IF NOT EXISTS (SELECT 1 FROM Finance.transactions WHERE transaction_id = p_transaction_id) THEN
--         v_errors := array_append(v_errors, 'Transaction ID does not exist');
--     END IF;
    
--     RETURN QUERY SELECT 
--         CASE WHEN array_length(v_errors, 1) IS NULL THEN TRUE ELSE FALSE END,
--         array_to_string(v_errors, '; ');
-- END;
-- $$ LANGUAGE plpgsql;