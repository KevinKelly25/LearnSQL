-- testClassMgmt.sql - LearnSQL

-- Michael Torres
-- Web Applications and Databases for Education (WADE)

-- This file tests the functions involved with class management in the LearnSQL
--  database



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
END;
$$;

/*------------------------------------------------------------------------------
    Define Temporary helper functions for assisting testClassMgmt functions
------------------------------------------------------------------------------*/

-- temp function class id if it exists learnsql tables and pg_database tables

-- create a role that is allowed create database



-- call the createClass function ('lksdfldfj' , 'fjldkjsfj', ...)
-- remember \l means select * from pg_database;

CREATE OR REPLACE FUNCTION 
  pg_temp.createAdminUser(username VARCHAR(60), 
                          password VARCHAR(64))
  RETURNS VOID AS 
$$
BEGIN 
  EXECUTE FORMAT('CREATE USER %s WITH PASSWORD %L CREATEDB', $1, $2);
  EXECUTE FORMAT('GRANT CONNECT ON DATABASE learnsql TO %s', $1);
  EXECUTE FORMAT('GRANT %s TO %s', 'classdb_admin', $1);
END;
$$ LANGUAGE plpgsql;

COMMIT;

-- TODO: check if the class exists in the database and in the learnsql tables
CREATE OR REPLACE FUNCTION
  pg_temp.checkIfClassIdExists(classid LearnSQL.Class_t.ClassID%Type)
  RETURN BOOLEAN AS 
$$
BEGIN 
  -- Check if the class exists in the postgres database
  IF NOT EXISTS (
                  SELECT 1 
                  FROM pg_database
                  WHERE datname = $1
                )
  THEN
    RETURN FALSE;
  END IF;

  -- Check if the class exists in the learnSQL Attends table
  IF NOT EXISTS (
                  SELECT 1 
                  FROM LearnSQL.Attends
                  WHERE Attends.classid = $1
                )
  THEN 
    RETURN FALSE;
  END IF;

  -- Check if the class exists in the learnSQL Class_t table
  IF NOT EXISTS (
                  SELECT 1 
                  FROM LearnSQL.Class_t
                  WHERE Class_t.classid = $1
                )
  THEN 
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- TODO: check if the class has all attributes (different functions for each)

-- TODO: check if the class is assigned to the correct professor.

SELECT pg_temp.createAdminUser('adminuser', 'password');
SELECT learnsql.createClass('adminuser', 'password', 'chochev3', 'pass', 'cs305', '01', '1:20 - 2:20pm', 'MW');