--CREATE DATABASE erp_db;

-- ================================================================================
-- SCHEMA CREATE
-- ================================================================================

-- Create schema
CREATE SCHEMA Finance;
CREATE SCHEMA Audit;
CREATE SCHEMA Compliance;
CREATE SCHEMA Staging;
CREATE SCHEMA Security;

-- Roles
CREATE ROLE finance_readonly;
CREATE ROLE dev_role;
CREATE ROLE admin_role;
CREATE ROLE audit_role;
CREATE ROLE erp_app;

-- Users (use secure password management in real deployment)
CREATE USER analyst WITH PASSWORD 'finance123';
CREATE USER dev_user WITH PASSWORD 'devpass123';
CREATE USER admin_user WITH PASSWORD 'adminpass123';
CREATE USER audit_user WITH PASSWORD 'auditpass123';

-- PUBLIC REVOKE
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- Admin: full access
GRANT ALL PRIVILEGES ON DATABASE erp_db TO admin_role;

GRANT ALL PRIVILEGES ON SCHEMA Finance TO admin_role;
GRANT ALL PRIVILEGES ON SCHEMA Staging TO admin_role;
GRANT ALL PRIVILEGES ON SCHEMA Compliance TO admin_role;
GRANT ALL PRIVILEGES ON SCHEMA Security TO admin_role;
GRANT ALL PRIVILEGES ON SCHEMA Audit TO admin_role;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA Finance TO admin_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA Audit TO admin_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA Staging TO admin_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA Compliance TO admin_role;

GRANT ALL ON ALL SEQUENCES IN SCHEMA Finance TO admin_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA Audit TO admin_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA Staging TO admin_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA Compliance TO admin_role;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA Finance TO dev_role;
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA Finance TO dev_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA Staging TO dev_role;
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA Staging TO dev_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA Compliance TO dev_role;
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA Compliance TO dev_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA Audit TO dev_role;
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA Audit TO dev_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA Finance GRANT ALL ON TABLES TO admin_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA Finance GRANT ALL ON SEQUENCES TO admin_role;

-- Repeat for other schemas as needed
ALTER DEFAULT PRIVILEGES IN SCHEMA Audit GRANT ALL ON TABLES TO admin_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA Audit GRANT ALL ON SEQUENCES TO admin_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA Staging GRANT ALL ON TABLES TO admin_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA Staging GRANT ALL ON SEQUENCES TO admin_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA Compliance GRANT ALL ON TABLES TO admin_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA Compliance GRANT ALL ON SEQUENCES TO admin_role;

GRANT admin_role TO admin_user;

-- optional but this big no no!
-- ALTER ROLE admin_user BYPASSRLS;

-- GRANT finance_readonly TO analyst;
-- GRANT dev_role TO dev_user;
-- GRANT admin_role TO admin_user;
-- GRANT audit_role TO audit_user;

-- -- Grant roles
-- GRANT finance_readonly TO analyst;
-- GRANT dev_role TO dev_user;
-- GRANT admin_role TO admin_user;
-- GRANT audit_role TO audit_user;

-- -- Developer privileges
-- GRANT CONNECT ON DATABASE erp_db TO dev_role;
-- GRANT USAGE, CREATE ON SCHEMA Finance TO dev_role;
-- GRANT USAGE, CREATE ON SCHEMA Staging TO dev_role;
-- GRANT USAGE, CREATE ON SCHEMA Audit TO dev_role;
-- GRANT USAGE, CREATE ON SCHEMA Compliance TO dev_role;

-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA Finance TO dev_role;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA Audit TO dev_role;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA Staging TO dev_role;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA Compliance TO dev_role;

-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA Finance TO dev_role;
-- GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA Finance TO dev_role;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA Staging TO dev_role;
-- GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA Staging TO dev_role;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA Compliance TO dev_role;
-- GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA Compliance TO dev_role;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA Audit TO dev_role;
-- GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA Audit TO dev_role;

-- -- Set defaults for future objects (for dev_user)
-- ALTER DEFAULT PRIVILEGES
-- FOR ROLE dev_user
-- IN SCHEMA Finance
-- GRANT ALL ON TABLES TO dev_role;

-- ALTER DEFAULT PRIVILEGES
-- FOR ROLE dev_user
-- IN SCHEMA Staging
-- GRANT ALL ON TABLES TO dev_role;

-- ALTER DEFAULT PRIVILEGES
-- FOR ROLE dev_user
-- IN SCHEMA Audit
-- GRANT ALL ON TABLES TO dev_role;

-- ALTER DEFAULT PRIVILEGES
-- FOR ROLE dev_user
-- IN SCHEMA Compliance
-- GRANT ALL ON TABLES TO dev_role;


-- -- Finance team: read-only
-- GRANT CONNECT ON DATABASE erp_db TO finance_readonly;
-- GRANT USAGE ON SCHEMA Finance TO finance_readonly;
-- GRANT SELECT ON ALL TABLES IN SCHEMA Finance TO finance_readonly;

-- -- Set defaults for future objects (for finance_readonly)
-- ALTER DEFAULT PRIVILEGES
-- FOR ROLE finance_readonly
-- IN SCHEMA Finance
-- GRANT SELECT ON TABLES TO finance_readonly;

-- -- Audit: read-only
-- GRANT CONNECT ON DATABASE erp_db TO audit_role;
-- GRANT USAGE ON SCHEMA Finance to audit_role;
-- GRANT USAGE ON SCHEMA Audit to audit_role;
-- GRANT SELECT ON ALL TABLES IN SCHEMA Finance to audit_role;
-- GRANT SELECT ON ALL TABLES IN SCHEMA Audit to audit_role;



-- -- Run this as dev_user or a superuser
-- -- 1. If YOU (the superuser) create the tables:
-- -- ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA Finance 
-- -- GRANT ALL ON TABLES TO admin_role;

-- -- ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA Finance 
-- -- GRANT ALL ON SEQUENCES TO admin_role;

-- -- 2. If you plan to use 'dev_user' to create tables in the future:
-- ALTER DEFAULT PRIVILEGES FOR ROLE dev_user IN SCHEMA Finance 
-- GRANT ALL ON TABLES TO admin_role;

-- ALTER DEFAULT PRIVILEGES FOR ROLE dev_user IN SCHEMA Finance 
-- GRANT ALL ON SEQUENCES TO admin_role;

-- -- app: Access
-- GRANT CONNECT ON DATABASE erp_db TO erp_app;
-- GRANT USAGE ON SCHEMA Finance TO erp_app;
-- GRANT USAGE ON SCHEMA Staging TO erp_app;
-- GRANT USAGE ON SCHEMA Audit TO erp_app;
-- GRANT USAGE ON SCHEMA Compliance TO erp_app;

\c erp_db

-- CREATE DATABASE erp_db;
-- -- ================================================================================
-- -- SCHEMA CREATE
-- -- ================================================================================
-- CREATE SCHEMA Finance;

-- -- ================================================================================
-- -- ROLE CREATE
-- -- ================================================================================

-- -- Finance team: read-only access
-- CREATE ROLE finance_readonly;

-- -- Developers: full access to schema
-- CREATE ROLE dev_role;

-- -- Admins: elevated privileges
-- CREATE ROLE admin_role;


-- -- ================================================================================
-- -- USER CREATE
-- -- ================================================================================

-- -- Finance analyst
-- CREATE USER analyst WITH PASSWORD 'finance123';

-- -- Developer
-- CREATE USER dev_user WITH PASSWORD 'devpass123';

-- -- Admin
-- CREATE USER admin_user WITH PASSWORD 'adminpass123';

-- -- ================================================================================
-- -- GRANTING ROLE TO USER
-- -- ================================================================================

-- GRANT finance_readonly TO analyst;
-- GRANT dev_role TO dev_user;
-- GRANT admin_role TO admin_user;


-- -- ================================================================================
-- -- PRIVILIGES GRANT TO ROLE
-- -- ================================================================================

-- -- Developers: full privileges on 
-- ---Database
-- GRANT CONNECT ON DATABASE erp_db TO dev_role;
-- --Schema privileges
-- GRANT USAGE CREATE ON SCHEMA Finance TO dev_role;

-- --Table privileges
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA Finance TO dev_role;

-- GRANT EXECUTE
-- ON ALL FUNCTIONS IN SCHEMA Finance
-- TO dev_role;

-- GRANT EXECUTE
-- ON ALL PROCEDURES IN SCHEMA Finance
-- TO dev_role;

-- ALTER DEFAULT PRIVILEGES
-- IN SCHEMA Finance
-- GRANT ALL
-- ON TABLES
-- TO dev_role;

-- --sequnce or objects
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA Finance TO dev_role;

-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA Finance TO dev_role;


-- -- Finance team: can only read data
-- --database privileges
-- GRANT CONNECT ON DATABASE erp_db TO finance_readonly;
-- --schema privileges
-- GRANT USAGE ON SCHEMA Finance TO finance_readonly;
-- --table privileges
-- GRANT SELECT ON ALL TABLES IN SCHEMA Finance TO finance_readonly;


-- ALTER DEFAULT PRIVILEGES
-- IN SCHEMA Finance
-- GRANT SELECT
-- ON TABLES
-- TO finance_readonly;

-- -- Admins: manage everything
-- --database privileges
-- GRANT CONNECT ON DATABASE erp_db TO admin_role;
-- GRANT ALL PRIVILEGES ON DATABASE erp_db TO admin_role;
-- --schema privileges
-- GRANT ALL PRIVILEGES ON SCHEMA Finance TO admin_role;
-- GRANT ALL PRIVILEGES ON SCHEMA public TO admin_role;
-- --table privileges
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA Finance TO admin_role;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_role;
-- --sequence privileges
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_role;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA Finance TO admin_role;

-- \c erp_db

-- CREATE TABLESPACE hotspace LOCATION '/mnt/ssd_hot';
-- CREATE TABLESPACE coldspace LOCATION '/mnt/hdd_cold';


-- ============================================================================

-- The command GRANT ALL PRIVILEGES is a shortcut that gives the user every possible right for that specific object.

-- 1. What does ALL PRIVILEGES actually include?
-- It depends on the object type:

-- On a TABLE:

-- SELECT: Read data.
-- INSERT: Add new rows.
-- UPDATE: Modify existing rows.
-- DELETE: Remove rows.
-- TRUNCATE: Empty the table.
-- REFERENCES: Create foreign key constraints.
-- INDEX: Create indexes on the table.

-- On a FUNCTION / PROCEDURE:

-- EXECUTE: Run the function or procedure.

-- On a SEQUENCE:

-- SELECT: Read the current value.
-- UPDATE: Change the current value (e.g., for auto-incrementing IDs).

-- On a SCHEMA:

-- USAGE: Access objects inside the schema.
-- CREATE: Create new objects (tables, functions) inside the schema.

-- On a DATABASE:

-- CONNECT: Log in to the database.
-- TEMPORARY or TEMP: Create temporary tables.
-- CREATE: (Often restricted to superusers, but in some contexts) Create schemas/objects.

-- ============================================================================

-- database level command can possible use
-- GRANT CONNECT ON DATABASE <DATABASE_NAME> TO <ROLE>
-- GRANT ALL PRIVILIGES ON DATABASE <DATABASE_NAME> TO <ROLE>
-- GRANT CREATE ON DATABASE <DATABASE_NAME> TO <ROLE>

-- schema level command can possible use
-- GRANT ALL PRIVILIGES ON SCHEMA <SCHEMA_NAME> TO <ROLE>
-- GRANT USAGE ON SCHEMA <SCHEMA_NAME> TO <ROLE>
-- GRANT CREATE ON SCHEMA <SCHEMA_NAME> TO <ROLE>

-- table level command can possible use
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA <SCHEMA_NAME> TO <ROLE>
-- GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCE, INDEX ON ALL TABLE IN SCHEMA <SCHEMA_NAME> TO <ROLE>
-- GRANT SELECT ON <TABLE_NAME>, <TABLE_NAME>, <TABLE_NAME> IN SCHEMA <SCHEMA_NAME> TO <ROLE>;
-- GRANT ALL PRIVILEGES ON <TABLE_NAME> <TABLE_NAME> <TABLE_NAME> IN SCHEMA <SCHEMA_NAME> TO <ROLE>;

-- sequence level command can possible use
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA <SCHEMA_NAME> TO <ROLE>
-- GRANT EXECUTE ON ALL PROCEDURE IN SCHEMA <SCHEMA_NAME> TO <ROLE>
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA <SCHEMA_NAME> TO <ROLE>
-- GRANT USAGE, CREATE ,UPDATEON ON ALL SEQUENCES IN SCHEMA <SCHEMA_NAME> TO <ROLE>

-- Here is my cheat sheet feel to make more better

-- -- 1. Database
-- GRANT CONNECT ON DATABASE <DATABASE_NAME> TO <ROLE_NAME>;
-- GRANT ALL PRIVILEGES ON DATABASE <DATABASE_NAME> TO <ROLE_NAME>;

-- -- 2. Schema
-- GRANT USAGE ON SCHEMA <SCHEMA_NAME> TO <ROLE_NAME>;
-- GRANT CREATE ON SCHEMA <SCHEMA_NAME> TO <ROLE_NAME>;
-- GRANT ALL PRIVILEGES ON SCHEMA <SCHEMA_NAME> TO <ROLE_NAME>;

-- -- 3. Tables
-- GRANT SELECT ON ALL TABLES IN SCHEMA <SCHEMA_NAME> TO <ROLE_NAME>;
-- GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA <SCHEMA_NAME> TO <ROLE_NAME>;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA <SCHEMA_NAME> TO <ROLE_NAME>;

-- -- 4. Functions
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA <SCHEMA_NAME> TO <ROLE_NAME>;
-- GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA <SCHEMA_NAME> TO <ROLE_NAME>;

-- -- 5. Sequences
-- GRANT USAGE ON ALL SEQUENCES IN SCHEMA <SCHEMA_NAME> TO <ROLE_NAME>;
-- GRANT SELECT ON ALL SEQUENCES IN SCHEMA <SCHEMA_NAME> TO <ROLE_NAME>;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA <SCHEMA_NAME> TO <ROLE_NAME>;

-- -- 6. Default Privileges (Run as Superuser or specific creator)
-- ALTER DEFAULT PRIVILEGES FOR ROLE <CREATOR_ROLE> IN SCHEMA <SCHEMA_NAME>
-- GRANT <PERMISSION> ON TABLES TO <TARGET_ROLE>;