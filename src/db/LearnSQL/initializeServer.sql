-- initializeServer.sql - LearnSQL

-- Kevin Kelly
-- Web Applications and Databases for Education (WADE)

-- This script runs the server setup

START TRANSACTION;

-- Make sure the current user has sufficient privilege to run this script
--  privilege required: superuser
DO
$$
BEGIN
  IF NOT EXISTS (
                  SELECT * FROM pg_catalog.pg_roles
                  WHERE rolname = CURRENT_USER AND rolsuper = TRUE
                ) 
  THEN
      RAISE EXCEPTION 'Insufficient privileges: script must be run as a user '
                      'with superuser privileges';
  END IF;
END
$$;

-- Create App-specific role
DO
$$
BEGIN
  -- Ensure the necessary classdb_admin role was already added. 
  IF NOT EXISTS (
                  SELECT * FROM pg_catalog.pg_roles
                  WHERE rolname = 'classdb_admin'
                ) 
  THEN
      RAISE EXCEPTION 'classdb_admin role should already exist'
            USING HINT = 'Please ensure ClassDB template has already been set up';
  END IF;

  -- Create user for role based access control on LearnSQL
  IF NOT EXISTS (
                  SELECT * FROM pg_catalog.pg_roles
                  WHERE rolname = 'learnsql'
                ) 
  THEN
      CREATE USER learnsql WITH CREATEDB CREATEROLE;
      GRANT classdb_admin to learnsql;
  END IF;
END
$$;

COMMIT;