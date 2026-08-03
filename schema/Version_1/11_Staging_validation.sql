BEGIN;

CREATE OR REPLACE PROCEDURE Staging.ar_import_workflow_validation(
    IN p_session_id INT
)
LANGUAGE plpgsql as $$
DECLARE
   -- table_related VARCHAR;
    new_session_id INT;
    r RECORD;
    z RECORD;
BEGIN

    SELECT session_id INTO new_session_id
    FROM Audit.import_sessions a
    WHERE a.session_id = p_session_id
    LIMIT 1;

    IF new_session_id IS NULL THEN
        RAISE EXCEPTION 'invalid Session ID : %', new_session_id;
    END IF;

    PERFORM 1 FROM Audit.import_sessions WHERE session_id = p_session_id;

    FOR r IN
        SELECT  a.*
                , b.row_number
                , c.field_name
        FROM Staging.stg_ar_imports a
        LEFT JOIN Staging.import_workflows b ON a.id = b.staging_record_id 
        LEFT JOIN Staging.import_detail_logs c ON c.row_number = b.row_number
        WHERE a.session_id = p_session_id
          AND validation_status = 'VALID'
          AND b.new_state = 'PENDING'
    LOOP

        SELECT *
        INTO z
        FROM Compliance.validate_ar_import(
            r.row_number::INT,
            r.customer_code::INT,
            r.amount::DECIMAL,
            r.invoice_date::DATE,
            r.due_date::DECIMAL,
            r.status::VARCHAR
        );

-- ========================================================
-- Amount
-- ========================================================
        
        if z.v_errors_amount IS NOT NULL THEN

            PERFORM Audit.import_validation(
                r.session_id, 
                r.row_number, 
                r.field_name, 
                'Check Amount Value!',
                r.amount,
                FALSE,
                'ERROR'
            );

            PERFORM Audit.log_compliance_check(
                r.client_code
                , 'Amount Check!'
                , 'Negative amount is not available'
                , 'AMOUNT_CHECK'
                , 'FAIL'
                , 'Kindly check your amount value!'
            );

        ELSE
        
            PERFORM Audit.import_validation(
                r.session_id, 
                r.row_number, 
                r.field_name, 
                'Valid Amount!',
                r.amount,
                TRUE,
                'INFO'
            );

            PERFORM Audit.log_compliance_check(
                r.client_code
                , 'Amount Check!'
                , 'Valid AMOUNT!'
                , 'AMOUNT_CHECK'
                , 'PASS'
                , 'Valid Amount!'
            );
            
            UPDATE Staging.import_workflows 
            SET 
                new_state = 'VALID',
                previous_state = 'PENDING'
            WHERE Staging.import_workflows.session_id = r.session_id
            AND Staging.import_workflows.staging_record_id = r.staging_record_id;

        END IF;

-- ========================================================
-- invoice
-- ========================================================

        if z.v_errors_invoice IS NOT NULL THEN
            
            PERFORM Audit.import_validation(
                r.session_id, 
                r.row_number, 
                r.field_name, 
                'Check invoice Value!',
                r.invoice_date,
                FALSE,
                'ERROR'
            );

            PERFORM Audit.log_compliance_check(
                r.client_code
                , 'Invoice Check!'
                , 'Invoice Date should not ahead to Due Date '
                , 'DATE_CHECK'
                , 'FAIL'
                , 'Kindly check your invoice date value!'
            ); 

        ELSE
            
            PERFORM Audit.import_validation(
                r.session_id, 
                r.row_number, 
                r.field_name, 
                'Valid Invoice Date!',
                r.invoice_date,
                TRUE,
                'INFO'
            );

            PERFORM Audit.log_compliance_check(
                r.client_code
                , 'Date Check!'
                , 'Valid Invoice Date!'
                , 'DATE_CHECK'
                , 'PASS'
                , 'Valid Invoice Date!'
            );
            
            UPDATE Staging.import_workflows 
            SET 
                new_state = 'VALID',
                previous_state = 'PENDING'
            WHERE Staging.import_workflows.session_id = r.session_id
            AND Staging.import_workflows.staging_record_id = r.staging_record_id;

        END IF;

-- ========================================================
-- Customer
-- ========================================================

        if z.v_errors_customer IS NOT NULL THEN
            
            PERFORM Audit.import_validation(
                r.session_id, 
                r.row_number, 
                r.field_name, 
                'Customer not exists!',
                r.invoice_date,
                FALSE,
                'ERROR'
            );

            PERFORM Audit.log_compliance_check(
                r.client_code
                , 'Customer Check!'
                , 'Customer does not exists!'
                , 'CUSTOMER_CHECK'
                , 'FAIL'
                , 'Kindly check your customer code value!'
            ); 

        ELSE
            PERFORM Audit.import_validation(
                r.session_id, 
                r.row_number, 
                r.field_name, 
                'Valid Customer!',
                r.invoice_date,
                TRUE,
                'INFO'
            );

            PERFORM Audit.log_compliance_check(
                r.client_code
                , 'Customer Check!'
                , 'Valid Customer!'
                , 'CUSTOMER_CHECK'
                , 'PASS'
                , 'Valid Customer code!'
            );
            
            UPDATE Staging.import_workflows 
            SET 
                new_state = 'VALID',
                previous_state = 'PENDING'
            WHERE Staging.import_workflows.session_id = r.session_id
            AND Staging.import_workflows.staging_record_id = r.staging_record_id;

        END IF;
-- ========================================================
-- Customer
-- ========================================================

        if z.v_errors_status IS NOT NULL THEN
            
            PERFORM Audit.import_validation(
                r.session_id, 
                r.row_number, 
                r.field_name, 
                'Status Check!',
                r.invoice_date,
                FALSE,
                'ERROR'
            );

        ELSE
            PERFORM Audit.import_validation(
                r.session_id, 
                r.row_number, 
                r.field_name, 
                'Valid Status!',
                r.invoice_date,
                TRUE,
                'INFO'
            );
        
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
        RAISE EXCEPTION 'Staging import workflow validation failed: %', SQLERRM;
END;
$$;

COMMIT;

SELECT 'Staging Schema import data validations complete' as Status;