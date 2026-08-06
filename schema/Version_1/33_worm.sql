BEGIN;

    CREATE OR REPLACE FUNCTION Audit.WORM()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
    SECURITY DEFINER
    SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;
    BEGIN
        
        RAISE EXCEPTION 'Direct Operation of Update and Delete is Prohibited';

    IF TG_OP = 'DELETE' THEN   
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;

    END;
    $$;

    CREATE TRIGGER Guard_worms
    BEFORE UPDATE OR DELETE ON Audit.record_lineage
    FOR EACH ROW EXECUTE FUNCTION Audit.WORM();

    CREATE TRIGGER Guard_worms_audit_logs
    BEFORE UPDATE OR DELETE ON Audit.audit_logs
    FOR EACH ROW EXECUTE FUNCTION Audit.WORM();

    CREATE TRIGGER Guard_worms_audit_log_extended
    BEFORE UPDATE OR DELETE ON Audit.audit_logs_extended
    FOR EACH ROW EXECUTE FUNCTION Audit.WORM();

    CREATE TRIGGER Guard_worms_import_detail_logs
    BEFORE UPDATE OR DELETE ON Audit.import_detail_logs
    FOR EACH ROW EXECUTE FUNCTION Audit.WORM();

    CREATE TRIGGER Guard_worms_compliance_logs
    BEFORE UPDATE OR DELETE ON Compliance.compliance_logs
    FOR EACH ROW EXECUTE FUNCTION Audit.WORM();

    CREATE TRIGGER Guard_worms_compliance_rules
    BEFORE UPDATE OR DELETE ON Compliance.compliance_rules
    FOR EACH ROW EXECUTE FUNCTION Audit.WORM();

    CREATE TRIGGER Guard_worms_reconciliation_tracking
    BEFORE UPDATE OR DELETE ON Audit.reconciliation_tracking
    FOR EACH ROW EXECUTE FUNCTION Audit.WORM();

    CREATE TRIGGER Guard_worms_approval_chain
    BEFORE UPDATE OR DELETE ON Audit.approval_chain
    FOR EACH ROW EXECUTE FUNCTION Audit.WORM();

    CREATE TRIGGER Guard_worms_transaction_lifecycle
    BEFORE UPDATE OR DELETE ON Audit.transaction_lifecycle
    FOR EACH ROW EXECUTE FUNCTION Audit.WORM();

    CREATE TRIGGER Guar_worms_import_validation_log
    BEFORE UPDATE OR DELETE ON Audit.import_validation_log
    FOR EACH ROW EXECUTE FUNCTION Audit.WORM();

    CREATE TRIGGER Guard_worms_import_session
    BEFORE UPDATE OR DELETE ON Audit.import_sessions
    FOR EACH ROW EXECUTE FUNCTION Audit.WORM();



COMMIT;

SELECT '33 WORM' AS STATUS;
