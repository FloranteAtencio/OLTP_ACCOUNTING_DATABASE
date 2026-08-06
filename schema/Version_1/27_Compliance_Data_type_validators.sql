BEGIN;

-- Email validator
DROP FUNCTION IF EXISTS Compliance.validate_email(VARCHAR) CASCADE;
CREATE FUNCTION Compliance.validate_email(p_email VARCHAR)
RETURNS TABLE (is_valid BOOLEAN, error_msg TEXT) AS $$
BEGIN
    IF p_email IS NULL OR p_email = '' THEN
        RETURN QUERY SELECT FALSE::BOOLEAN, 'Email cannot be empty'::TEXT;
    ELSIF p_email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$' THEN
        RETURN QUERY SELECT FALSE::BOOLEAN, 'Invalid email format'::TEXT;
    ELSE
        RETURN QUERY SELECT TRUE::BOOLEAN, ''::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;


-- Phone validator
DROP FUNCTION IF EXISTS Compliance.validate_phone(VARCHAR) CASCADE;
CREATE FUNCTION Compliance.validate_phone(p_phone VARCHAR)
RETURNS TABLE (is_valid BOOLEAN, error_msg TEXT) AS $$
BEGIN
    IF p_phone IS NULL OR p_phone = '' THEN
        RETURN QUERY SELECT TRUE::BOOLEAN, ''::TEXT;  -- Phone can be empty
    ELSIF p_phone !~ '^\+?1?\d{9,15}$' THEN
        RETURN QUERY SELECT FALSE::BOOLEAN, 'Invalid phone format'::TEXT;
    ELSE
        RETURN QUERY SELECT TRUE::BOOLEAN, ''::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;


-- Decimal amount validator
DROP FUNCTION IF EXISTS Compliance.validate_decimal_amount(VARCHAR) CASCADE;
CREATE FUNCTION Compliance.validate_decimal_amount(p_amount VARCHAR)
RETURNS TABLE (is_valid BOOLEAN, error_msg TEXT, parsed_value DECIMAL) AS $$
DECLARE
    v_parsed DECIMAL;
BEGIN
    BEGIN
        v_parsed := p_amount::DECIMAL;
        IF v_parsed < 0 THEN
            RETURN QUERY SELECT FALSE::BOOLEAN, 'Amount cannot be negative'::TEXT, NULL::DECIMAL;
        ELSE
            RETURN QUERY SELECT TRUE::BOOLEAN, ''::TEXT, v_parsed::DECIMAL;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT FALSE::BOOLEAN, 'Invalid decimal format: ' || p_amount::TEXT, NULL::DECIMAL;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;


-- Integer quantity validator
DROP FUNCTION IF EXISTS Compliance.validate_integer_quantity(VARCHAR) CASCADE;
CREATE FUNCTION Compliance.validate_integer_quantity(p_quantity VARCHAR)
RETURNS TABLE (is_valid BOOLEAN, error_msg TEXT, parsed_value INT) AS $$
DECLARE
    v_parsed INT;
BEGIN
    BEGIN
        v_parsed := p_quantity::INT;
        IF v_parsed <= 0 THEN
            RETURN QUERY SELECT FALSE::BOOLEAN, 'Quantity must be greater than 0'::TEXT, NULL::INT;
        ELSE
            RETURN QUERY SELECT TRUE::BOOLEAN, ''::TEXT, v_parsed::INT;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT FALSE::BOOLEAN, 'Invalid integer format: ' || p_quantity::TEXT, NULL::INT;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;


-- Date validator
DROP FUNCTION IF EXISTS Compliance.validate_date(VARCHAR) CASCADE;
CREATE FUNCTION Compliance.validate_date(p_date VARCHAR)
RETURNS TABLE (is_valid BOOLEAN, error_msg TEXT, parsed_value DATE) AS $$
DECLARE
    v_parsed DATE;
BEGIN
    BEGIN
        v_parsed := p_date::DATE;
        IF v_parsed > CURRENT_DATE THEN
            RETURN QUERY SELECT FALSE::BOOLEAN, 'Date cannot be in the future'::TEXT, NULL::DATE;
        ELSE
            RETURN QUERY SELECT TRUE::BOOLEAN, ''::TEXT, v_parsed::DATE;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT FALSE::BOOLEAN, 'Invalid date format: ' || p_date::TEXT, NULL::DATE;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;


COMMIT;
SELECT '27 Compliance data type validators' AS STATUS;