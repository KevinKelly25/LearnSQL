-- testUserMgmt.sql - LearnSQL

-- Kevin Kelly
-- Web Applications and Databases for Education (WADE)

-- This file tests the functions involved with user management in the LearnSQL
--  database.


START TRANSACTION;

--Make sure the current user has sufficient privilege to run this script
-- privilege required: superuser
DO
$$
BEGIN
   IF NOT EXISTS (SELECT * FROM pg_catalog.pg_roles
                  WHERE rolname = CURRENT_USER AND rolsuper = TRUE
                 ) THEN
      RAISE EXCEPTION 'Insufficient privileges: script must be run as a user '
                      'with superuser privileges';
   END IF;
END
$$;

/*------------------------------------------------------------------------------
    Define Temporary helper functions for assisting testUserMgmt functions
------------------------------------------------------------------------------*/


--Define a temporary function to test if the username exists in both the database
-- and the UserData table
CREATE OR REPLACE FUNCTION
  pg_temp.checkIfUsernameExists(UserName  LearnSQL.UserData_t.UserName%Type)
   RETURNS BOOLEAN AS
$$
BEGIN
   --Check if username is a postgres rolename
  IF NOT EXISTS (
                  SELECT *
                  FROM pg_catalog.pg_roles
                  WHERE rolname = $1 
                )
  THEN
      RETURN FALSE;
  END IF;

  --Check if username is a LearnSQL user
  IF EXISTS (
              SELECT *
              FROM LearnSQL.UserData_t
              WHERE UserName = $1; 
            )
  THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;



--Define a temporary function to test if the user has given associated FullName
CREATE OR REPLACE FUNCTION
  pg_temp.checkFullName(UserName  LearnSQL.UserData_t.UserName%Type,
                        FullName  LearnSQL.UserData_t.FullName%Type)
   RETURNS BOOLEAN AS
$$
BEGIN
  --Check if username is a LearnSQL user
  IF EXISTS (
              SELECT *
              FROM LearnSQL.UserData_t
              WHERE UserName = $1 AND FullName = $2; 
            )
  THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;



--Define a temporary function to test if the username has given associated 
-- password
--We currently store the passwords with MD5. On postgres the table pg_authid
-- stores these passwords. However, md5 is added to the beginning and before
-- hashing the password the user's username is appended to password. 
CREATE OR REPLACE FUNCTION
  pg_temp.checkPassword(UserName  LearnSQL.UserData_t.UserName%Type,
                        Password  VARCHAR(256))
   RETURNS BOOLEAN AS
$$
BEGIN
  --Taken and modified from ClassDB testClassDBRoleMgmt.sql
  --Authors: Andrew Figueroa, Steven Rollo, Sean Murthy
  IF EXISTS (
             SELECT * FROM pg_catalog.pg_authid
             WHERE RolName = $1 AND (
                RolPassword = 'md5' || pg_catalog.MD5($2 || $1)
                OR (RolPassword IS NULL AND $2 IS NULL) )
            )
  THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;


--Define a temporary function to test if the user has given associated FullName
CREATE OR REPLACE FUNCTION
  pg_temp.checkEmail(UserName  LearnSQL.UserData_t.UserName%Type,
                     Email     LearnSQL.UserData_t.Email%Type)
   RETURNS BOOLEAN AS
$$
BEGIN
  IF EXISTS (
              SELECT *
              FROM LearnSQL.UserData_t
              WHERE UserName = $1 AND Email = $2; 
            )
  THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;



--Define a temporary function to test if the user is a teacher
CREATE OR REPLACE FUNCTION
  pg_temp.isTeacher(UserName  LearnSQL.UserData_t.UserName%Type)
  RETURNS BOOLEAN AS
$$
BEGIN
  IF EXISTS (
              SELECT *
              FROM LearnSQL.UserData_t
              WHERE UserName = $1 AND isTeacher; 
            )
  THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;

--Define a temporary function to test if the user is an admin
CREATE OR REPLACE FUNCTION
  pg_temp.isAdmin(UserName  LearnSQL.UserData_t.UserName%Type)
  RETURNS BOOLEAN AS
$$
BEGIN
  IF EXISTS (
              SELECT *
              FROM LearnSQL.UserData_t
              WHERE UserName = $1 AND isAdmin; 
            )
  THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;

/*------------------------------------------------------------------------------
                 End of Temporary functions helpers
------------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------
            Define Test Functions for checking userMgmt functionality
------------------------------------------------------------------------------*/

CREATE OR REPLACE FUNCTION pg_temp.createAndDropUserTest() RETURNS TEXT AS
$$
BEGIN
  --Create user with basic privileges 
  PERFORM LearnSQL.createUser('testUser0', 'Test user 0', 'testPass0',
                              'testUser0@testemail.com');
  --Create user with teacher privileges 
  PERFORM LearnSQL.createUser('testUser1', 'Test user 1', 'testPass1',
                              'testUser1@testemail.com', true);

    --Create user with teacher and admin privileges 
  PERFORM LearnSQL.createUser('testUser2', 'Test user 2', 'testPass2',
                              'testUser1@testemail.com', true, true);

  --Check if the username was created and properly set
  IF NOT (pg_temp.checkIfUsernameExists('testUser0')
     AND  pg_temp.checkIfUsernameExists('testUser1')
     AND  pg_temp.checkIfUsernameExists('testUser1')) 
  THEN
    RETURN 'Fail Code 1';
  END IF;

  --Check if the full name set
  IF NOT (pg_temp.checkFullName('Test User 0')
     AND  pg_temp.checkFullName('Test User 1')
     AND  pg_temp.checkFullName('Test User 1')) 
  THEN
    RETURN 'Fail Code 2';
  END IF;


                              --not done
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION pg_temp.userMgmtTest() RETURNS VOID AS
$$
BEGIN
   RAISE INFO '%   createAndDropUserTest()', pg_temp.createAndDropUserTest();
END;
$$  LANGUAGE plpgsql;


SELECT pg_temp.userMgmtTest();



--ignore all test data
ROLLBACK;