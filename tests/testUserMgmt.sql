-- testUserMgmt.sql - LearnSQL

-- Kevin Kelly
-- Web Applications and Databases for Education (WADE)

-- This file tests the functions involved with user management in the LearnSQL
--  database


START TRANSACTION;



-- Suppress NOTICE messages for this script: won't apply to functions created here
--  hides unimportant but possibly confusing msgs generated as the script executes
SET LOCAL client_min_messages TO WARNING;



-- Make sure the current user has sufficient privilege to run this script
--  privilege required: superuser
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


-- Define a temporary function to test if the username exists in both the database
--  and the UserData table
CREATE OR REPLACE FUNCTION
  pg_temp.checkIfUsernameExists(UserName  LearnSQL.UserData_t.UserName%Type)
  RETURNS BOOLEAN AS
$$
BEGIN
   -- Check if username is a postgres rolename
  IF NOT EXISTS (
                  SELECT *
                  FROM pg_catalog.pg_roles
                  WHERE rolname = $1 
                )
  THEN
      RETURN FALSE;
  END IF;

  -- Check if username is a LearnSQL user
  IF EXISTS (
              SELECT *
              FROM LearnSQL.UserData_t
              WHERE UserData_t.UserName = $1
            )
  THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;



-- Define a temporary function to test if the user has given associated FullName
CREATE OR REPLACE FUNCTION
  pg_temp.checkFullName(UserName  LearnSQL.UserData_t.UserName%Type,
                        FullName  LearnSQL.UserData_t.FullName%Type)
   RETURNS BOOLEAN AS
$$
BEGIN
  -- Check if username is a LearnSQL user
  IF EXISTS (
              SELECT *
              FROM LearnSQL.UserData_t
              WHERE UserData_t.UserName = $1 AND UserData_t.FullName = $2 
            )
  THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;



-- Define a temporary function to test if the username has given associated 
--  password
CREATE OR REPLACE FUNCTION
  pg_temp.checkPassword(UserName  LearnSQL.UserData_t.UserName%Type,
                        Password  VARCHAR(256))
   RETURNS BOOLEAN AS
$$
DECLARE
  encryptedPassword VARCHAR(60); --hashed password from UserData_t
BEGIN
  SELECT UserData_t.password INTO encryptedPassword
  FROM LearnSQL.UserData_t 
  WHERE UserData_t.UserName = $1;

  -- If password is matches after hashing then this is true
  IF (encryptedPassword = crypt($2, encryptedPassword))
  THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;


-- Define a temporary function to test if the user has given associated FullName
CREATE OR REPLACE FUNCTION
  pg_temp.checkEmail(UserName  LearnSQL.UserData_t.UserName%Type,
                     Email     LearnSQL.UserData_t.Email%Type)
   RETURNS BOOLEAN AS
$$
BEGIN
  IF EXISTS (
              SELECT *
              FROM LearnSQL.UserData_t
              WHERE UserData_t.UserName = $1 AND UserData_t.Email = $2 
            )
  THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;



-- Define a temporary function to test if the user is a teacher
CREATE OR REPLACE FUNCTION
  pg_temp.isTeacher(UserName  LearnSQL.UserData_t.UserName%Type)
  RETURNS BOOLEAN AS
$$
BEGIN
  IF EXISTS (
              SELECT *
              FROM LearnSQL.UserData_t
              WHERE UserData_t.UserName = $1 AND UserData_t.isTeacher
            )
  THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;



-- Define a temporary function to test if the user is an admin
CREATE OR REPLACE FUNCTION
  pg_temp.isAdmin(UserName  LearnSQL.UserData_t.UserName%Type)
  RETURNS BOOLEAN AS
$$
BEGIN
  IF EXISTS (
              SELECT *
              FROM LearnSQL.UserData_t
              WHERE UserData_t.UserName = $1 AND UserData_t.isAdmin
            )
  THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Define a temporary function to test if the username exists in both the 
--  database and the UserData table
CREATE OR REPLACE FUNCTION
  pg_temp.checkIfDropped(UserName  LearnSQL.UserData_t.UserName%Type)
   RETURNS BOOLEAN AS
$$
BEGIN
   -- Check if username is a postgres rolename
  IF EXISTS (
              SELECT *
              FROM pg_catalog.pg_roles
              WHERE rolname = $1 
            )
  THEN
      RETURN FALSE;
  END IF;

  -- Check if username is a LearnSQL user
  IF EXISTS (
              SELECT *
              FROM LearnSQL.UserData_t
              WHERE UserData_t.UserName = $1
            )
  THEN
    RETURN FALSE;
  ELSE
    RETURN TRUE;
  END IF;
END;
$$ LANGUAGE plpgsql;


-- Define a temporary function to delete the user in userdata_t table and the
--  database role without the need of a database password like in dropUser()
-- Should only be used to clean up at the end of test functions
CREATE OR REPLACE FUNCTION
  pg_temp.dropUser(UserName  LearnSQL.UserData_t.UserName%Type)
  RETURNS VOID AS
$$
BEGIN
  -- Delete user from LearnSQL tables
  DELETE FROM LearnSQL.UserData_t WHERE UserData_t.Username = $1;

  -- Check if username is a postgres rolename and if so delete
  IF EXISTS (
              SELECT *
              FROM pg_catalog.pg_roles
              WHERE rolname = $1 
            )
  THEN
    -- Delete role from database
    EXECUTE FORMAT('DROP USER %s',$1);
  END IF;
END;
$$ LANGUAGE plpgsql;

/*------------------------------------------------------------------------------
                 End of Temporary functions helpers
------------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------
            Define Test Functions for checking userMgmt functionality
------------------------------------------------------------------------------*/

-- This function tests the creation and delete of users for the LearnSQL database
--  as well as the server roles. 
CREATE OR REPLACE FUNCTION pg_temp.createAndDropUserTest() RETURNS TEXT AS
$$
BEGIN
  -- Ensure the test users do not exist
  PERFORM pg_temp.dropUser('testuser0');
  PERFORM pg_temp.dropUser('testuser1');
  PERFORM pg_temp.dropUser('testuser2');

  -- Create user with basic privileges 
  PERFORM LearnSQL.createUser('testuser0', 'Test user 0', 'testPass0',
                              'testUser0@testemail.com',
                              '7a92db10c4cb11e8b5680800200c9a66');

  -- Create user with teacher privileges 
  PERFORM LearnSQL.createUser('testuser1', 'Test user 1', 'testPass1',
                              'testUser1@testemail.com',
                              '9f40a820c4cb11e8b5680800200c9a66', true);

    -- Create user with teacher and admin privileges 
  PERFORM LearnSQL.createUser('testuser2', 'Test user 2', 'testPass2',
                              'testUser2@testemail.com',
                              'b57810b0c4cb11e8b5680800200c9a66', true, true);

  -- Check if the username was created and properly set
  IF NOT (pg_temp.checkIfUsernameExists('testuser0')
     AND  pg_temp.checkIfUsernameExists('testuser1')
     AND  pg_temp.checkIfUsernameExists('testuser2')) 
  THEN
    RETURN 'Fail Code 1';
  END IF;

  -- Check if the full name set
  IF NOT (pg_temp.checkFullName('testuser0','Test user 0')
     AND  pg_temp.checkFullName('testuser1','Test user 1')
     AND  pg_temp.checkFullName('testuser2','Test user 2')) 
  THEN
    RETURN 'Fail Code 2';
  END IF;

  -- Check if the password was correctly set
  IF NOT (pg_temp.checkPassword('testuser0', 'testPass0')
     AND  pg_temp.checkPassword('testuser1', 'testPass1')
     AND  pg_temp.checkPassword('testuser2', 'testPass2')) 
  THEN
    RETURN 'Fail Code 3';
  END IF;

  -- Check if the email was correctly set
  IF NOT (pg_temp.checkEmail('testuser0', 'testUser0@testemail.com')
     AND  pg_temp.checkEmail('testuser1', 'testUser1@testemail.com')
     AND  pg_temp.checkEmail('testuser2', 'testUser2@testemail.com')) 
  THEN
    RETURN 'Fail Code 4';
  END IF;

  -- Check if the test user's isTeacher status is correct
  IF NOT (NOT pg_temp.isTeacher('testuser0')-- Should not be teacher
     AND  pg_temp.isTeacher('testuser1')
     AND  pg_temp.isTeacher('testuser2')) 
  THEN
    RETURN 'Fail Code 5';
  END IF;

  -- Check if the test user's isTeacher status is correct
  IF NOT (NOT pg_temp.isAdmin('testuser0')-- Should not be admin
     AND  NOT pg_temp.isAdmin('testuser1')-- Should not be admin
     AND  pg_temp.isAdmin('testuser2')) 
  THEN
    RETURN 'Fail Code 6';
  END IF;
  
  -- Drop All Test users. Ignore values are provided so that it deletes role
  --  without needing database password. This would break drop function if there
  --  was classes connected to user but since we know there is not we can do this
  PERFORM LearnSQL.dropUser('testuser0', 'ignore', 'ignore');
  PERFORM LearnSQL.dropUser('testuser1', 'ignore', 'ignore');
  PERFORM LearnSQL.dropUser('testuser2', 'ignore', 'ignore');

  -- Check that the users were successfully dropped
  IF NOT (pg_temp.checkIfDropped('testuser0')
     AND  pg_temp.checkIfDropped('testuser1')
     AND  pg_temp.checkIfDropped('testuser2')) 
  THEN
    RETURN 'Fail Code 7';
  END IF;

  RETURN 'Passed';

END;
$$ LANGUAGE plpgsql;



-- This function tests the changeUsername function. This function creates 3 test
--  accounts and then changes their name. It then checks to make sure that
--  the new username exists
CREATE OR REPLACE FUNCTION pg_temp.changeUsernameTest() RETURNS TEXT AS
$$
BEGIN
  -- Ensure the test users do not exist
  PERFORM pg_temp.dropUser('testuser0');
  PERFORM pg_temp.dropUser('testuser1');
  PERFORM pg_temp.dropUser('testuser2');

  -- Create user with basic privileges 
  PERFORM LearnSQL.createUser('testuser0', 'Test user 0', 'testPass0',
                              'testUser0@testemail.com',
                              '7a92db10c4cb11e8b5680800200c9a66');

  -- Create user with teacher privileges 
  PERFORM LearnSQL.createUser('testuser1', 'Test user 1', 'testPass1',
                              'testUser1@testemail.com',
                              '9f40a820c4cb11e8b5680800200c9a66', true);

    -- Create user with teacher and admin privileges 
  PERFORM LearnSQL.createUser('testuser2', 'Test user 2', 'testPass2',
                              'testUser2@testemail.com',
                              'b57810b0c4cb11e8b5680800200c9a66', true, true);

  -- Change all usernames 
  PERFORM LearnSQL.changeUsername('testuser0', 'testuser3');
  PERFORM LearnSQL.changeUsername('testuser1', 'testuser4');
  PERFORM LearnSQL.changeUsername('testuser2', 'testuser5');

  -- Check if the username was changed
  IF NOT (pg_temp.checkIfUsernameExists('testuser3')
     AND  pg_temp.checkIfUsernameExists('testuser4')
     AND  pg_temp.checkIfUsernameExists('testuser5')) 
  THEN
    RETURN 'Fail Code 1';
  END IF;

  --Check if the previous usernames still exist
  IF (pg_temp.checkIfUsernameExists('testuser0')
     AND  pg_temp.checkIfUsernameExists('testuser1')
     AND  pg_temp.checkIfUsernameExists('testuser2')) 
  THEN
    RETURN 'Fail Code 2';
  END IF;

  --Clean up test users
  PERFORM pg_temp.dropUser('testuser3');
  PERFORM pg_temp.dropUser('testuser4');
  PERFORM pg_temp.dropUser('testuser5');

  RETURN 'Passed';

END;
$$ LANGUAGE plpgsql;



--This function tests the changePassword function. This function creates 3 test
-- accounts and then changes their Password. It then checks to make sure that
-- the password exists in the Userdata_t table
CREATE OR REPLACE FUNCTION pg_temp.changePasswordTest() RETURNS TEXT AS
$$
BEGIN
  -- Ensure the test users do not exist
  PERFORM pg_temp.dropUser('testuser0');
  PERFORM pg_temp.dropUser('testuser1');
  PERFORM pg_temp.dropUser('testuser2');

  -- Create user with basic privileges 
  PERFORM LearnSQL.createUser('testuser0', 'Test user 0', 'testPass0',
                              'testuser0@testemail.com',
                              '7a92db10c4cb11e8b5680800200c9a66');

  -- Create user with teacher privileges 
  PERFORM LearnSQL.createUser('testuser1', 'Test user 1', 'testPass1',
                              'testuser1@testemail.com',
                              '9f40a820c4cb11e8b5680800200c9a66', true);

    -- Create user with teacher and admin privileges 
  PERFORM LearnSQL.createUser('testuser2', 'Test user 2', 'testPass2',
                              'testuser2@testemail.com',
                              'b57810b0c4cb11e8b5680800200c9a66', true, true);

  -- Change all usernames 
  PERFORM LearnSQL.changePassword('testuser0', 'testPass0', 'newPass0');
  PERFORM LearnSQL.changePassword('testuser1', 'testPass1', 'newPass1');
  PERFORM LearnSQL.changePassword('testuser2', 'testPass2', 'newPass2');

  -- Check if the username was changed
  IF NOT (pg_temp.checkPassword('testuser0', 'newPass0')
     AND  pg_temp.checkPassword('testuser1', 'newPass1')
     AND  pg_temp.checkPassword('testuser2', 'newPass2')) 
  THEN
    RETURN 'Fail Code 1';
  END IF;

  -- Clean up test users
  PERFORM pg_temp.dropUser('testuser0');
  PERFORM pg_temp.dropUser('testuser1');
  PERFORM pg_temp.dropUser('testuser2');

  RETURN 'Passed';

END;
$$ LANGUAGE plpgsql;



--This function tests the changeFullName function. This function creates 3 test
-- accounts and then changes their Full Name. It then checks to make sure that
-- the FullName exists in the Userdata_t table for that given user
CREATE OR REPLACE FUNCTION pg_temp.changeFullNameTest() RETURNS TEXT AS
$$
BEGIN
  --Ensure the test users do not exist
  PERFORM pg_temp.dropUser('testuser0');
  PERFORM pg_temp.dropUser('testuser1');
  PERFORM pg_temp.dropUser('testuser2');


  -- Create user with basic privileges 
  PERFORM LearnSQL.createUser('testuser0', 'Test user 0', 'testPass0',
                              'testuser0@testemail.com',
                              '7a92db10c4cb11e8b5680800200c9a66');

  -- Create user with teacher privileges 
  PERFORM LearnSQL.createUser('testuser1', 'Test user 1', 'testPass1',
                              'testuser1@testemail.com',
                              '9f40a820c4cb11e8b5680800200c9a66', true);

    -- Create user with teacher and admin privileges 
  PERFORM LearnSQL.createUser('testuser2', 'Test user 2', 'testPass2',
                              'testuser2@testemail.com',
                              'b57810b0c4cb11e8b5680800200c9a66', true, true);

  -- Change all usernames 
  PERFORM LearnSQL.changeFullName('testuser0', 'New Full Name 0');
  PERFORM LearnSQL.changeFullName('testuser1', 'New Full Name 1');
  PERFORM LearnSQL.changeFullName('testuser2', 'New Full Name 2');

  -- Check if the username was changed
  IF NOT (pg_temp.checkFullName('testuser0', 'New Full Name 0')
     AND  pg_temp.checkFullName('testuser1', 'New Full Name 1')
     AND  pg_temp.checkFullName('testuser2', 'New Full Name 2')) 
  THEN
    RETURN 'Fail Code 1';
  END IF;

  -- Clean up test users
  PERFORM pg_temp.dropUser('testuser0');
  PERFORM pg_temp.dropUser('testuser1');
  PERFORM pg_temp.dropUser('testuser2');

  RETURN 'Passed';

END;
$$ LANGUAGE plpgsql;



-- This function tests the changeEmail function. This function creates 3 test
--  accounts and then changes their Email. It then checks to make sure that
--  the Email exists in the Userdata_t table for that user
CREATE OR REPLACE FUNCTION pg_temp.changeEmailTest() RETURNS TEXT AS
$$
BEGIN
  --Ensure the test users do not exist
  PERFORM pg_temp.dropUser('testuser0');
  PERFORM pg_temp.dropUser('testuser1');
  PERFORM pg_temp.dropUser('testuser2');

  -- Create user with basic privileges 
  PERFORM LearnSQL.createUser('testuser0', 'Test user 0', 'testPass0',
                              'testUser0@testemail.com',
                              '7a92db10c4cb11e8b5680800200c9a66');

  -- Create user with teacher privileges 
  PERFORM LearnSQL.createUser('testuser1', 'Test user 1', 'testPass1',
                              'testUser1@testemail.com',
                              '9f40a820c4cb11e8b5680800200c9a66', true);

    -- Create user with teacher and admin privileges 
  PERFORM LearnSQL.createUser('testuser2', 'Test user 2', 'testPass2',
                              'testuser2@testemail.com',
                              'b57810b0c4cb11e8b5680800200c9a66', true, true);

  -- Change all usernames 
  PERFORM LearnSQL.changeEmail('testuser0', 'newEmail0@testemail.com');
  PERFORM LearnSQL.changeEmail('testuser1', 'newEmail1@testemail.com');
  PERFORM LearnSQL.changeEmail('testuser2', 'newEmail2@testemail.com');

  -- Check if the username was changed
  IF NOT (pg_temp.checkEmail('testuser0', 'newEmail0@testemail.com')
     AND  pg_temp.checkEmail('testuser1', 'newEmail1@testemail.com')
     AND  pg_temp.checkEmail('testuser2', 'newEmail2@testemail.com')) 
  THEN
    RETURN 'Fail Code 1';
  END IF;

  -- Clean up test users
  PERFORM pg_temp.dropUser('testuser0');
  PERFORM pg_temp.dropUser('testuser1');
  PERFORM pg_temp.dropUser('testuser2');

  RETURN 'Passed';

END;
$$ LANGUAGE plpgsql;



-- This function tests the forgotPasswordReset function. This function creates 3 test
--  accounts and then resets thier password with forgotPasswordReset Function.
--  It then checks to make sure that the Email exists in the Userdata_t table for that user.
CREATE OR REPLACE FUNCTION pg_temp.forgotPasswordResetTest() RETURNS TEXT AS
$$
BEGIN
  -- Ensure the test users do not exist
  PERFORM pg_temp.dropUser('testuser0');
  PERFORM pg_temp.dropUser('testuser1');
  PERFORM pg_temp.dropUser('testuser2');

  -- Create user with basic privileges 
  PERFORM LearnSQL.createUser('testuser0', 'Test user 0', 'testPass0',
                              'testUser0@testemail.com',
                              '7a92db10c4cb11e8b5680800200c9a66');

  -- Create user with teacher privileges 
  PERFORM LearnSQL.createUser('testuser1', 'Test user 1', 'testPass1',
                              'testUser1@testemail.com',
                              '9f40a820c4cb11e8b5680800200c9a66', true);

    -- Create user with teacher and admin privileges 
  PERFORM LearnSQL.createUser('testuser2', 'Test user 2', 'testPass2',
                              'testUser2@testemail.com',
                              'b57810b0c4cb11e8b5680800200c9a66', true, true);

  -- Change all usernames 
  PERFORM LearnSQL.forgotPasswordReset('testuser0', 
                                      '7a92db10c4cb11e8b5680800200c9a66', 
                                       'newPass0');
  PERFORM LearnSQL.forgotPasswordReset('testuser1', 
                                       '9f40a820c4cb11e8b5680800200c9a66',
                                       'newPass1');
  PERFORM LearnSQL.forgotPasswordReset('testuser2', 
                                       'b57810b0c4cb11e8b5680800200c9a66', 
                                       'newPass2');

  -- Check if the username was changed
  IF NOT (pg_temp.checkPassword('testuser0', 'newPass0')
     AND  pg_temp.checkPassword('testuser1', 'newPass1')
     AND  pg_temp.checkPassword('testuser2', 'newPass2')) 
  THEN
    RETURN 'Fail Code 1';
  END IF;

  -- Clean up test users
  PERFORM pg_temp.dropUser('testuser0');
  PERFORM pg_temp.dropUser('testuser1');
  PERFORM pg_temp.dropUser('testuser2');

  RETURN 'Passed';

END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION pg_temp.userMgmtTest() RETURNS VOID AS
$$
BEGIN
   RAISE INFO '%   createAndDropUserTest()',  pg_temp.createAndDropUserTest();
   RAISE INFO '%   changeUsernameTest()',     pg_temp.changeUsernameTest();
   RAISE INFO '%   changePasswordTest()',     pg_temp.changePasswordTest();
   RAISE INFO '%   changeFullNameTest()',     pg_temp.changeFullNameTest();
   RAISE INFO '%   changeEmailTest()',        pg_temp.changeEmailTest();
   RAISE INFO '%   forgotPasswordResetTest()',pg_temp.forgotPasswordResetTest();
END;
$$  LANGUAGE plpgsql;


SELECT pg_temp.userMgmtTest();



-- Ignore all test data
ROLLBACK;