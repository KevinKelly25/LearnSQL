-- userMgmt.sql - LearnSQL

-- Kevin Kelly
-- Web Applications and Databases for Education (WADE)

-- This file creates the functions involved with user management in the LearnSQL
--  database.This file should be run after createLearnSQLTables.sql

START TRANSACTION;


--Define function to register a user and perform corresponding configuration
CREATE OR REPLACE FUNCTION
  LearnSQL.createUser(UserName VARCHAR(256),
                      FullName VARCHAR(256),
                      Password VARCHAR(60),
                      Email    VARCHAR(319))
   RETURNS TEXT AS
$$
BEGIN
  --Check if username exists
  IF EXISTS (SELECT *
             FROM UserData_t
             WHERE UserName = $1
      ) THEN
    RETURN 'Username Already Exists';
  END IF;


  --Check if username exists
  IF EXISTS (SELECT *
             FROM UserData_t
             WHERE UserName = $1
      ) THEN
    RETURN 'Username Already Exists';
  END IF;

END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER;




COMMIT;