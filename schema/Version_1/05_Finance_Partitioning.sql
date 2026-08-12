BEGIN;

-- 1. Fixed: Added 'date' type to e_date
CREATE OR REPLACE FUNCTION Finance.partition_monthly_basis(tableselected text, schemaselected text)
RETURNS void AS $$
DECLARE
    s_date date := date_trunc('month', current_date);
    e_date date := s_date + interval '1 month'; -- FIXED: Added 'date'
    part_name text;    
BEGIN
    IF schemaselected NOT IN ('Finance','Audit','Staging','Compliance') THEN
        RAISE EXCEPTION 'Invalid schema %', schemaselected;
    END IF;

    IF tableselected NOT IN ('journals', 'ar_ext', 'ap_ext', 'inventory_audits') THEN
        RAISE EXCEPTION 'Invalid table %', tableselected;
    END IF;

    part_name := tableselected || '_' || to_char(s_date,'YYYY_MM') || '_m' || extract(month from s_date);

    EXECUTE format(
        'CREATE TABLE IF NOT EXISTS %I PARTITION OF %I.%I 
        FOR VALUES FROM (%L) TO (%L)
        TABLESPACE hotspace;',
        part_name, schemaselected, tableselected, s_date, e_date
    );

    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Finance partition monthly basis : % : %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;


CREATE OR REPLACE FUNCTION Finance.partition_weekly_basis(tableselected text, schemaselected text)
RETURNS void AS $$
DECLARE
    s_date date := date_trunc('week', current_date);
    e_date date := s_date + interval '7 days';
    part_name text;    
BEGIN
    IF schemaselected NOT IN ('Finance','Audit','Staging','Compliance') THEN
        RAISE EXCEPTION 'Invalid schema %', schemaselected;
    END IF;

    IF tableselected NOT IN ('journals', 'ar_ext', 'ap_ext', 'inventory_audits') THEN
        RAISE EXCEPTION 'Invalid table %', tableselected;
    END IF;

    part_name := tableselected || '_' || to_char(s_date,'YYYY_MM') || '_wk' || extract(week from s_date);

    EXECUTE format(
        'CREATE TABLE IF NOT EXISTS %I PARTITION OF %I.%I 
        FOR VALUES FROM (%L) TO (%L)
        TABLESPACE hotspace;',
        part_name, schemaselected, tableselected, s_date, e_date
    );

    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Finance partition weekly basis : % : %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;

 
-- 2. Fixed: Parameter name 'schemaselect' used consistently
CREATE OR REPLACE FUNCTION alter_tables_space_weekly_basis(
    schemaselect text,
    tableselected text
)
RETURNS void AS $$
DECLARE
    start_date date := current_date - interval '7 days';
    part_name text;
BEGIN
    IF schemaselect NOT IN ('Finance','Audit','Staging','Compliance') THEN -- FIXED: Used schemaselect
        RAISE EXCEPTION 'Invalid schema %', schemaselect;
    END IF;

    IF tableselected NOT IN ('journals', 'ar_ext', 'ap_ext', 'inventory_audits') THEN
        RAISE EXCEPTION 'Invalid table %', tableselected;
    END IF;

    part_name := tableselected || '_' || to_char(start_date, 'YYYY_MM') || '_wk' || extract(week from start_date);

    EXECUTE format(
        'ALTER TABLE %I.%I SET TABLESPACE coldspace;',
        schemaselect,
        part_name
    );
    
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Finance partition monthly basis : % : %', SQLSTATE, SQLERRM;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;


-- 3. Fixed: Parameter name 'schemaselect' used consistently
CREATE OR REPLACE FUNCTION alter_tables_space_monthly_basis(
    schemaselect text,
    tableselected text
)
RETURNS void AS $$
DECLARE
    start_date date := current_date - interval '30 days';
    part_name text;
BEGIN
    IF schemaselect NOT IN ('Finance','Audit','Staging','Compliance') THEN -- FIXED: Used schemaselect
        RAISE EXCEPTION 'Invalid schema %', schemaselect;
    END IF;

    IF tableselected NOT IN ('journals', 'ar_ext', 'ap_ext', 'inventory_audits') THEN
        RAISE EXCEPTION 'Invalid table %', tableselected;
    END IF;

    part_name := tableselected || '_' || to_char(start_date, 'YYYY_MM') || '_m' || extract(month from start_date);

    EXECUTE format(
        'ALTER TABLE %I.%I SET TABLESPACE coldspace;',
        schemaselect,
        part_name
    );
    
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Finance partition monthly basis : % : %', SQLSTATE, SQLERRM;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = Finance, Audit, Compliance, Security, Staging, pg_catalog;


-- 4. Fixed: Corrected function name typo in comments (partion -> partition)
-- 0 2 * * 0 docker exec -it erp_postgres psql -U erp_admin -d erp_db -c "Select Finance.partition_weekly_basis('Finance','journals');"
-- 0 2 1 * * docker exec -it erp_postgres psql -U erp_admin -d erp_db -c "Select Finance.partition_monthly_basis('Finance','journals');"

COMMIT;

SELECT '05 Finance Schema Partitioning Complete!' as Status;

-- 0 2 * * 0 docker exec -it erp_postgres psql -U erp_admin -d erp_db -c \ "Select alter_tables_space_weekly_basis('Finance','journals');"
-- 0 2 1 * * docker exec -it erp_postgres psql -U erp_admin -d erp_db -c \ "Select alter_tables_space_monthly_basis('Finance','accountpayables');"
-- 0 2 1 * * docker exec -it erp_postgres psql -U erp_admin -d erp_db -c \ "Select alter_tables_space_monthly_basis('Finance','accountreceivables');"
-- 0 2 1 * * docker exec -it erp_postgres psql -U erp_admin -d erp_db -c \ "Select alter_tables_space_monthly_basis('Finance','inventoryaudits');"

-- 0 2 * * 0 docker exec -it erp_postgres psql -U erp_admin -d erp_db -c \ "Select partion_monthly_basis('Finance','journals');"
-- 0 2 1 * * docker exec -it erp_postgres psql -U erp_admin -d erp_db -c \ "Select partion_monthly_basis('Finance','accountpayables');"
-- 0 2 1 * * docker exec -it erp_postgres psql -U erp_admin -d erp_db -c \ "Select partion_monthly_basis('Finance','accountreceivables');"
-- 0 2 1 * * docker exec -it erp_postgres psql -U erp_admin -d erp_db -c \ "Select partion_monthly_basis('Finance','inventoryaudits');"

-- CREATE OR REPLACE FUNCTION alter_tables_space_weekly_basis_counting_base_on_month(
--     schemaselect text,
--     tableselected text
-- )
-- RETURNS void AS $$
-- DECLARE
--     start_date date := current_date - interval '7 days';
--     month_start date := date_trunc('month', start_date);
--     week_number int;
--     part_name text;
-- BEGIN
--     -- Calculate week number relative to the month
--     week_number := ((extract(day from start_date) - 1) / 7)::int + 1;

--     -- Build partition name like journals_2026_03_wk1
--     part_name := tableselected || '_' ||
--                  to_char(start_date, 'YYYY_MM') || '_wk' ||
--                  week_number;

--     -- Move partition to coldspace
--     EXECUTE format(
--         'ALTER TABLE %I.%I SET TABLESPACE coldspace;',
--         schemaselect,
--         part_name
--     );
-- END;
-- $$ LANGUAGE plpgsql;

