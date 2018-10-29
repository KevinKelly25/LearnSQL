-- testClassMgmt.sql - LearnSQL

-- Michael Torres
-- Web Applications and Databases for Education (WADE)

-- This file tests the functions involved with class management in the LearnSQL
--  database



START TRANSACTION;

/*
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
END;
$$;*/

/*------------------------------------------------------------------------------
    Define Temporary helper functions for assisting testClassMgmt functions
------------------------------------------------------------------------------*/

-- temp function class id if it exists learnsql tables and pg_database tables

-- create a role that is allowed create database



-- call the createClass function ('lksdfldfj' , 'fjldkjsfj', ...)
-- remember \l means select * from pg_database;

CREATE OR REPLACE FUNCTION 
  LearnSQL.createDatabaseUser()
  RETURNS VOID AS 
$$
BEGIN 

  EXECUTE FORMAT('CREATE USER %s WITH PASSWORD %L CREATEDB', 'testuser', 'password');
  EXECUTE FORMAT('GRANT CONNECT ON DATABASE %s TO %s', 'LearnSQL', 'testuser');
  EXECUTE FORMAT('GRANT %s TO %s', 'classdb', 'testuser');
END;
$$ LANGUAGE plpgsql;

COMMIT;

SELECT LearnSQL.createDatabaseUser();
 
/*CREATE OR REPLACE FUNCTION
  LearnSQL.createClassTest()
  RETURNS VOID AS 
$$
BEGIN 
    EXECUTE 'SELECT learnsql.createClass(''testuser'', ''password'', ''chochev3'', ''pass'', ''cs305'', ''01'', ''1:20 - 2:20pm'', ''MW'')';
END;
$$ LANGUAGE plpgsql;

  SELECT LearnSQL.createClassTest();*/

SELECT learnsql.createClass('testuser', 'password', 'chochev3', 'pass', 'cs305', '01', '1:20 - 2:20pm', 'MW');