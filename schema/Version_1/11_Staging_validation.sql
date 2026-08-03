BEGIN;

CREATE OR REPLACE PROCEDURE Staging.ar_import_workflow_validation(
    IN p_session_id INT
)
LANGUAGE plpgsql as $$
DECLARE
    new_session_id INT;
    r RECORD;
    z RECORD; -- This will hold the 4 error columns
BEGIN
    -- 1. Validate Session
    SELECT session_id INTO new_session_id
    FROM Audit.import_sessions a
    WHERE a.session_id = p_session_id
    LIMIT 1;

    IF new_session_id IS NULL THEN
        RAISE EXCEPTION 'Invalid Session ID: %', p_session_id; -- Fixed: use p_session_id, not new_session_id (which is NULL)
    END IF;

    -- 2. Loop through records
    FOR r IN
        SELECT 
            a.*, 
            c.row_number, 
            c.table_name
        FROM Staging.stg_ar_imports a
        LEFT JOIN Staging.import_workflows b ON a.id = b.staging_record_id 
        LEFT JOIN Audit.import_detail_logs c ON c.session_id = b.session_id
        WHERE a.session_id = p_session_id
          AND (b.new_state = 'PENDING' OR b.new_state IS NULL) -- Fixed: Handle case where workflow row might not exist yet
    LOOP

        -- Call the validation function
        SELECT *
        INTO z
        FROM Compliance.validate_ar_import(
            r.row_number::INT,
            r.customer_code::INT,
            r.amount::DECIMAL,
            r.invoice_date::DATE,
            r.due_date::DATE,
            r.status::VARCHAR
        );

        -- ========================================================
        -- Amount Check
        -- ========================================================
        -- FIX: Use z.amount_error instead of z.v_errors_amount
        IF z.amount_error IS NOT NULL THEN
            PERFORM Compliance.import_validation(
                r.session_id, r.row_number, r.table_name, 
                'Check Amount Value!', r.amount, FALSE, 'ERROR'
            );
            PERFORM Compliance.log_compliance_check(
                r.client_code::INT, 'Amount Check!'::VARCHAR, 'Negative amount is not available', 
                'AMOUNT_CHECK'::VARCHAR, 'FAIL'::VARCHAR, 'Kindly check your amount value!'
            );
        ELSE
            PERFORM Compliance.import_validation(
                r.session_id, r.row_number, r.table_name, 
                'Valid Amount!', r.amount, TRUE, 'INFO'
            );
            PERFORM Compliance.log_compliance_check(
                r.client_code::INT, 'Amount Check!'::VARCHAR, 'Valid AMOUNT!', 
                'AMOUNT_CHECK'::VARCHAR, 'PASS'::VARCHAR, 'Valid Amount!'
            );
        END IF;

        -- ========================================================
        -- Invoice Date Check
        -- ========================================================
        -- FIX: Use z.Invoice_error instead of z.v_errors_invoice
        IF z.Invoice_error IS NOT NULL THEN
            PERFORM Compliance.import_validation(
                r.session_id, r.row_number, r.table_name, 
                'Check Invoice Value!', r.invoice_date, FALSE, 'ERROR'
            );
            PERFORM Compliance.log_compliance_check(
                r.client_code::INT, 'Invoice Check!'::VARCHAR, 'Invoice Date should not be ahead of Due Date', 
                'DATE_CHECK'::VARCHAR, 'FAIL'::VARCHAR, 'Kindly check your invoice date value!'
            );
        ELSE
            PERFORM Compliance.import_validation(
                r.session_id, r.row_number, r.table_name, 
                'Valid Invoice Date!', r.invoice_date, TRUE, 'INFO'
            );
            PERFORM Compliance.log_compliance_check(
                r.client_code::INT, 'Date Check!'::VARCHAR, 'Valid Invoice Date!', 
                'DATE_CHECK'::VARCHAR, 'PASS'::VARCHAR, 'Valid Invoice Date!'
            );
        END IF;

        -- ========================================================
        -- Customer Check
        -- ========================================================
        -- FIX: Use z.customer_error instead of z.v_errors_customer
        IF z.customer_error IS NOT NULL THEN
            PERFORM Compliance.import_validation(
                r.session_id, r.row_number, r.table_name, 
                'Customer not exists!', r.customer_code, FALSE, 'ERROR'
            );
            PERFORM Compliance.log_compliance_check(
                r.client_code::INT, 'Customer Check!'::VARCHAR, 'Customer does not exist', 
                'CUSTOMER_CHECK'::VARCHAR, 'FAIL'::VARCHAR, 'Kindly check your customer code value!'
            );
        ELSE
            PERFORM Compliance.import_validation(
                r.session_id, r.row_number, r.table_name, 
                'Valid Customer!', r.customer_code, TRUE, 'INFO'
            );
            PERFORM Compliance.log_compliance_check(
                r.client_code::INT, 'Customer Check!'::VARCHAR, 'Valid Customer!', 
                'CUSTOMER_CHECK'::VARCHAR, 'PASS'::VARCHAR, 'Valid Customer code!'
            );
        END IF;

        -- ========================================================
        -- Status Check
        -- ========================================================
        -- FIX: Use z.status_error instead of z.v_errors_status
        IF z.status_error IS NOT NULL THEN
            PERFORM Compliance.import_validation(
                r.session_id, r.row_number, r.table_name, 
                'Status Check!', r.status, FALSE, 'ERROR'
            );
            -- Log status fail if needed
            PERFORM Compliance.log_compliance_check(
                r.client_code::INT, 'Status Check!'::VARCHAR, 'Invalid AR status', 
                'STATUS_CHECK'::VARCHAR, 'FAIL'::VARCHAR, 'Kindly check your status value!'
            );
        ELSE
            PERFORM Compliance.import_validation(
                r.session_id, r.row_number, r.table_name, 
                'Valid Status!', r.status, TRUE, 'INFO'
            );
            -- Log status pass if needed
            PERFORM Compliance.log_compliance_check(
                r.client_code::INT, 'Status Check!'::VARCHAR, 'Valid Status!', 
                'STATUS_CHECK'::VARCHAR, 'PASS'::VARCHAR, 'Valid Status!'
            );
        END IF;

        -- ========================================================
        -- Update Workflow Status (Only if ALL checks passed)
        -- ========================================================
        -- Logic: If ANY error was found, we should NOT update to 'VALID'.
        -- We only update if ALL four are NULL.
        IF z.amount_error IS NULL 
           AND z.Invoice_error IS NULL 
           AND z.customer_error IS NULL 
           AND z.status_error IS NULL THEN
            
            UPDATE Staging.import_workflows 
            SET 
                new_state = 'VALID',
                previous_state = 'PENDING'
            WHERE Staging.import_workflows.session_id = r.session_id
              AND Staging.import_workflows.staging_record_id = r.staging_record_id;
        END IF;
    
    END LOOP;    

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Procedure ar_import_workflow_validation failed: %', SQLERRM;
END;
$$;

COMMIT;

SELECT 'Staging Schema import data validations complete' as Status;