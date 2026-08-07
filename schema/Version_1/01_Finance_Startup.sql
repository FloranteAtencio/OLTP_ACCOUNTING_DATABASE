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
CREATE ROLE readonly_role;
CREATE ROLE admin_role;
CREATE ROLE app_role;

-- Users (use secure password management in real deployment)
CREATE USER analyst WITH PASSWORD 'finance123';
CREATE USER admin_user WITH PASSWORD 'adminpass123';
CREATE USER app_user WITH PASSWORD 'appuser123'

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
ALTER DEFAULT PRIVILEGES IN SCHEMA Audit GRANT ALL ON TABLES TO admin_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA Audit GRANT ALL ON SEQUENCES TO admin_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA Staging GRANT ALL ON TABLES TO admin_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA Staging GRANT ALL ON SEQUENCES TO admin_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA Compliance GRANT ALL ON TABLES TO admin_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA Compliance GRANT ALL ON SEQUENCES TO admin_role;

-- =============================================================================================
-- Application user privileges
-- =============================================================================================

GRANT CONNECT ON DATABASE erp_db TO app_role;

GRANT USAGE ON SCHEMA Finance TO app_role;
GRANT USAGE ON SCHEMA Audit TO app_role;
GRANT USAGE ON SCHEMA compliance TO app_role;
GRANT USAGE ON SCHEMA Staging TO app_role;

GRANT SELECT ON ALL TABLES IN SCHEMA Audit TO app_role;
GRANT SELECT ON ALL TABLES IN SCHEMA Compliance TO app_role;
GRANT SELECT, UPDATE, DELETE, INSERT ON ALL TABLES IN SCHEMA Staging TO app_role;
GRANT SELECT, UPDATE, DELETE, INSERT ON ALL TABLES IN SCHEMA Finance TO app_role;

GRANT ALL ON ALL SEQUENCES IN SCHEMA Finance TO app_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA Audit TO app_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA Staging TO app_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA Compliance TO app_role;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA Finance TO app_role;
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA Finance TO app_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA Staging TO app_role;
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA Staging TO app_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA Compliance TO app_role;
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA Compliance TO app_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA Audit TO app_role;
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA Audit TO app_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA Finance GRANT ALL ON TABLES TO app_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA Finance GRANT ALL ON SEQUENCES TO app_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA Audit GRANT ALL ON TABLES TO app_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA Audit GRANT ALL ON SEQUENCES TO app_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA Staging GRANT ALL ON TABLES TO app_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA Staging GRANT ALL ON SEQUENCES TO app_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA Compliance GRANT ALL ON TABLES TO app_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA Compliance GRANT ALL ON SEQUENCES TO app_role;

-- =============================================================================================
-- Application user privileges
-- =============================================================================================
GRANT CONNECT ON DATABASE erp_db TO readonly_role;

GRANT USEAGE ON SCHEMA Finance TO readonly_role;
GRANT USEAGE ON SCHEMA Audit TO readonly_role;
GRANT USEAGE ON SCHEMA Compliance TO readonly_role;
GRANT USEAGE ON SCHEMA Staging TO readonly_role;

GRANT SELECT ON ALL TABLES IN SCHEMA Finance TO readonly_role;
GRANT SELECT ON ALL TABLES IN SCHEMA Audit TO readonly_role;
GRANT SELECT ON ALL TABLES IN SCHEMA Compliance TO readonly_role;
GRANT SELECT ON ALL TABLES IN SCHEMA Staging TO readonly_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA Finance GRANT ALL ON TABLES TO app_role;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA Finance GRANT ALL ON SEQUENCES TO app_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA Audit GRANT ALL ON TABLES TO app_role;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA Audit GRANT ALL ON SEQUENCES TO app_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA Staging GRANT ALL ON TABLES TO app_role;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA Staging GRANT ALL ON SEQUENCES TO app_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA Compliance GRANT ALL ON TABLES TO app_role;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA Compliance GRANT ALL ON SEQUENCES TO app_role;

GRANT admin_role TO admin_user;
GRANT app_role TO app_user;
GRANT readonly_role TO analyst;
-- ============================================================================
-- Guide lines
-- ============================================================================
-- 1. Privileges on a SCHEMA
-- These control what a user can do inside the container itself.

-- Privilege	         Description	                                                                    Common Use Case
-- CREATE	            Allows creating new objects (tables, views, functions) inside the schema.	        Developers needing to build new features.
-- USAGE	            Allows the user to access the schema and its objects.                               Without this, they cannot see or use anything inside, even if they have table permissions.	Essential for almost everyone who needs to query the schema.
-- TEMPORARY (or TEMP)	Allows creating temporary tables (visible only to the session) within the schema.	Debugging or session-specific data processing.
-- Note: You generally cannot grant DROP on a schema directly to a non-owner.                               Dropping a schema usually requires ownership or superuser rights. However, if a user can CREATE tables, they can usually DROP the tables they created.

-- 2. Privileges on a TABLE (and Views/Sequences)
-- These control what a user can do to the specific data or structure of the table.

-- Privilege	    Description	                                            Common Use Case
-- SELECT	        Read data (rows and columns).	                        Analysts, Read-Only apps, Auditors.
-- INSERT	        Add new rows.	                                        ETL jobs, Staging imports (09_Staging_Import_data_session.sql).
-- UPDATE	        Modify existing rows.	                                Data correction scripts, Staging sanitation (10_Staging_sanitation.sql).
-- DELETE	        Remove rows.	                                        Cleaning staging data, archiving.
-- TRUNCATE	        Quickly delete all rows in the table.	                Resetting staging tables before a new load.
-- REFERENCES	    Allows creating foreign keys that reference this table.	Developers building relationships between tables.
-- TRIGGER	        Allows creating triggers on the table.	                Rarely granted to devs in prod; usually reserved for DBAs.
-- ALL PRIVILEGES	Grants every permission listed above.	                Avoid in production finance schemas.
-- Note on DROP: There is no DROP privilege on a specific table.

-- Owner Rule: If you grant CREATE on the schema, the user becomes the owner of any table they create. Owners can always DROP their own tables.
-- Non-Owners: To let a user drop a table they don't own, you usually need to grant them DROP on the schema (in some DBs like SQL Server) or make them a member of the schema owner role (PostgreSQL). In standard PostgreSQL, DROP on a table is an ownership right, not a grantable privilege on the object itself.

-- 3. Special Case: SEQUENCES
-- Since your finance schema likely uses sequences for IDs (e.g., Finance_Startup.sql), you might need these:

-- Privilege	Description
-- USAGE	    Allows using nextval() (getting the next ID).
-- UPDATE	    Allows setval() (manually setting the ID).
-- SELECT	    Allows reading the current value (currval()).

-- 4. Special Case: FUNCTIONS / PROCEDURES
-- For your audit functions (19_Audit_log_functions.sql) or validators (24_Compliance_Business_Logic_validators.sql):

-- Privilege	Description
-- EXECUTE	    Allows running the function or stored procedure.

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