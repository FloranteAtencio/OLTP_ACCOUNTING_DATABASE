
-- ============================================
-- 2. BUSINESS LOGIC VALIDATORS
-- ============================================

BEGIN;

-- Customer exists validator
DROP FUNCTION IF EXISTS Compliance.validate_customer_exists(INT) CASCADE;
CREATE FUNCTION Compliance.validate_customer_exists(p_customer_id INT)
RETURNS TABLE (is_valid BOOLEAN, error_msg TEXT) AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM Finance.customers WHERE customer_id = p_customer_id) THEN
        RETURN QUERY SELECT TRUE::BOOLEAN, ''::TEXT;
    ELSE
        RETURN QUERY SELECT FALSE::BOOLEAN, 'Customer ID does not exist: ' || p_customer_id::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;


-- Vendor exists validator
DROP FUNCTION IF EXISTS Compliance.validate_vendor_exists(INT) CASCADE;
CREATE FUNCTION Compliance.validate_vendor_exists(p_vendor_id INT)
RETURNS TABLE (is_valid BOOLEAN, error_msg TEXT) AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM Finance.vendors WHERE vendor_id = p_vendor_id) THEN
        RETURN QUERY SELECT TRUE::BOOLEAN, ''::TEXT;
    ELSE
        RETURN QUERY SELECT FALSE::BOOLEAN, 'Vendor ID does not exist: ' || p_vendor_id::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;


-- Product exists validator
DROP FUNCTION IF EXISTS Compliance.validate_product_exists(INT) CASCADE;
CREATE FUNCTION Compliance.validate_product_exists(p_product_id INT)
RETURNS TABLE (is_valid BOOLEAN, error_msg TEXT) AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM Finance.products WHERE product_id = p_product_id) THEN
        RETURN QUERY SELECT TRUE::BOOLEAN, ''::TEXT;
    ELSE
        RETURN QUERY SELECT FALSE::BOOLEAN, 'Product ID does not exist: ' || p_product_id::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;


-- Warehouse exists validator
DROP FUNCTION IF EXISTS Compliance.validate_warehouse_exists(INT) CASCADE;
CREATE FUNCTION Compliance.validate_warehouse_exists(p_warehouse_id INT)
RETURNS TABLE (is_valid BOOLEAN, error_msg TEXT) AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM Finance.warehouses WHERE warehouse_id = p_warehouse_id) THEN
        RETURN QUERY SELECT TRUE::BOOLEAN, ''::TEXT;
    ELSE
        RETURN QUERY SELECT FALSE::BOOLEAN, 'Warehouse ID does not exist: ' || p_warehouse_id::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;


-- Account exists validator
DROP FUNCTION IF EXISTS Compliance.validate_account_exists(INT) CASCADE;
CREATE FUNCTION Compliance.validate_account_exists(p_chart_id INT)
RETURNS TABLE (is_valid BOOLEAN, error_msg TEXT) AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM Finance.charts WHERE chart_id = p_chart_id AND is_active = TRUE) THEN
        RETURN QUERY SELECT TRUE::BOOLEAN, ''::TEXT;
    ELSE
        RETURN QUERY SELECT FALSE::BOOLEAN, 'Account ID does not exist or is inactive: ' || p_chart_id::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;


-- Transaction balance validator (debit = credit)
DROP FUNCTION IF EXISTS Compliance.validate_transaction_balance(INT) CASCADE;
CREATE FUNCTION Compliance.validate_transaction_balance(p_transaction_id INT)
RETURNS TABLE (is_valid BOOLEAN, error_msg TEXT, debit_total DECIMAL, credit_total DECIMAL) AS $$
DECLARE
    v_debit DECIMAL;
    v_credit DECIMAL;
BEGIN
    SELECT COALESCE(SUM(CASE WHEN journal = TRUE THEN amount ELSE 0 END), 0),
           COALESCE(SUM(CASE WHEN journal = FALSE THEN amount ELSE 0 END), 0)
    INTO v_debit, v_credit
    FROM Finance.journals
    WHERE transaction_id = p_transaction_id;
    
    IF v_debit = v_credit THEN
        RETURN QUERY SELECT TRUE::BOOLEAN, ''::TEXT, v_debit, v_credit;
    ELSE
        RETURN QUERY SELECT FALSE::BOOLEAN, 
            'Debit/Credit imbalance. Debit: ' || v_debit::TEXT || ' Credit: ' || v_credit::TEXT,
            v_debit, v_credit;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;


-- Invoice date <= due date validator
DROP FUNCTION IF EXISTS Compliance.validate_invoice_due_dates(DATE, DATE) CASCADE;
CREATE FUNCTION Compliance.validate_invoice_due_dates(p_invoice_date DATE, p_due_date DATE)
RETURNS TABLE (is_valid BOOLEAN, error_msg TEXT) AS $$
BEGIN
    IF p_invoice_date > p_due_date THEN
        RETURN QUERY SELECT FALSE::BOOLEAN, 'Invoice date cannot be after due date'::TEXT;
    ELSE
        RETURN QUERY SELECT TRUE::BOOLEAN, ''::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;


-- Receivable overdue check
DROP FUNCTION IF EXISTS Compliance.is_receivable_overdue(DATE) CASCADE;
CREATE FUNCTION Compliance.is_receivable_overdue(p_due_date DATE)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN p_due_date < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;
 

-- Payable overdue check
DROP FUNCTION IF EXISTS Compliance.is_payable_overdue(DATE) CASCADE;
CREATE FUNCTION Compliance.is_payable_overdue(p_due_date DATE)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN p_due_date < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;



COMMIT;

SELECT '24 Compliance business logic validation' AS STATUS;