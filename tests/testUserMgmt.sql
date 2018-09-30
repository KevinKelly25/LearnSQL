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
  pg_temp.checkIfUsernameExists(UserName  UserData_t.UserName%Type)
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
              FROM UserData_t
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
  pg_temp.checkFullName(UserName  UserData_t.UserName%Type,
                        FullName  UserData_t.FullName%Type)
   RETURNS BOOLEAN AS
$$
BEGIN
  --Check if username is a LearnSQL user
  IF EXISTS (
              SELECT *
              FROM UserData_t
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
CREATE OR REPLACE FUNCTION
  pg_temp.checkPassword(UserName  UserData_t.UserName%Type,
                        Password  VARCHAR(256))
   RETURNS BOOLEAN AS
$$
DECLARE
  encryptedPassword VARCHAR(60); --hashed password from UserData_t
BEGIN
  encryptedPassword = SELECT password FROM LearnSQL.UserData_t 
                      WHERE UserData_t.UserName = $1;
  --If password is matches after hashing then this is true
  IF (encryptedPassword = crypt($2, encryptedPassword))
  THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;


--Define a temporary function to test if the user has given associated FullName
CREATE OR REPLACE FUNCTION
  pg_temp.checkEmail(UserName  UserData_t.UserName%Type,
                     Email     UserData_t.Email%Type)
   RETURNS BOOLEAN AS
$$
BEGIN
  IF EXISTS (
              SELECT *
              FROM UserData_t
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
  pg_temp.isTeacher(UserName  UserData_t.UserName%Type)
  RETURNS BOOLEAN AS
$$
BEGIN
  IF EXISTS (
              SELECT *
              FROM UserData_t
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
  pg_temp.isAdmin(UserName  UserData_t.UserName%Type)
  RETURNS BOOLEAN AS
$$
BEGIN
  IF EXISTS (
              SELECT *
              FROM UserData_t
              WHERE UserName = $1 AND isAdmin; 
            )
  THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;

--Define a temporary function to test if the username exists in both the database
-- and the UserData table
CREATE OR REPLACE FUNCTION
  pg_temp.checkIfDropped(UserName  UserData_t.UserName%Type)
   RETURNS BOOLEAN AS
$$
BEGIN
   --Check if username is a postgres rolename
  IF EXISTS (
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
              FROM UserData_t
              WHERE UserName = $1; 
            )
  THEN
    RETURN FALSE;
  ELSE
    RETURN TRUE;
  END IF;
END;
$$ LANGUAGE plpgsql;

/*------------------------------------------------------------------------------
                 End of Temporary functions helpers
------------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------
            Define Test Functions for checking userMgmt functionality
------------------------------------------------------------------------------*/

--This function tests the creation and delete of users for the LearnSQL database
-- as well as the server roles. 
CREATE OR REPLACE FUNCTION pg_temp.createAndDropUserTest() RETURNS TEXT AS
$$
BEGIN

  --Make sure that the roles don't exist already. If they do make sure they are
  -- dropped.
  DROP ROLE IF EXISTS testuser0;
  DROP ROLE IF EXISTS testuser1;
  DROP ROLE IF EXISTS testuser2;


  --Create user with basic privileges 
  PERFORM createUser('testUser0', 'Test user 0', 'testPass0',
                     '7a92db10c4cb11e8b5680800200c9a66', 
                     'testUser0@testemail.com');
  --Create user with teacher privileges 
  PERFORM createUser('testUser1', 'Test user 1', 'testPass1',
                     '9f40a820c4cb11e8b5680800200c9a66',
                     'testUser1@testemail.com', true);

    --Create user with teacher and admin privileges 
  PERFORM createUser('testUser2', 'Test user 2', 'testPass2',
                     'b57810b0c4cb11e8b5680800200c9a66',
                     'testUser2@testemail.com', true, true);

  --Check if the username was created and properly set
  IF NOT (pg_temp.checkIfUsernameExists('testUser0')
     AND  pg_temp.checkIfUsernameExists('testUser1')
     AND  pg_temp.checkIfUsernameExists('testUser2')) 
  THEN
    RETURN 'Fail Code 1';
  END IF;

  --Check if the full name set
  IF NOT (pg_temp.checkFullName('Test User 0')
     AND  pg_temp.checkFullName('Test User 1')
     AND  pg_temp.checkFullName('Test User 2')) 
  THEN
    RETURN 'Fail Code 2';
  END IF;

  --Check if the password was correctly set
  IF NOT (pg_temp.checkPassword('TestUser0', 'testPass0')
     AND  pg_temp.checkPassword('TestUser1', 'testPass1')
     AND  pg_temp.checkPassword('TestUser2', 'testPass2')) 
  THEN
    RETURN 'Fail Code 3';
  END IF;

  --Check if the email was correctly set
  IF NOT (pg_temp.checkEmail('TestUser0', 'testUser0@testemail.com')
     AND  pg_temp.checkEmail('TestUser1', 'testUser1@testemail.com')
     AND  pg_temp.checkEmail('TestUser2', 'testUser2@testemail.com')) 
  THEN
    RETURN 'Fail Code 4';
  END IF;

  --Check if the test user's isTeacher status is correct
  IF NOT (NOT pg_temp.isTeacher('TestUser0')--should not be teacher
     AND  pg_temp.isTeacher('TestUser1')
     AND  pg_temp.isTeacher('TestUser2')) 
  THEN
    RETURN 'Fail Code 5';
  END IF;

  --Check if the test user's isTeacher status is correct
  IF NOT (NOT pg_temp.isAdmin('TestUser0')--should not be admin
     AND  NOT pg_temp.isAdmin('TestUser1')--should not be admin
     AND  pg_temp.isAdmin('TestUser2')) 
  THEN
    RETURN 'Fail Code 6';
  END IF;

  --Drop All Test users
  PERFORM dropUser('TestUser0');
  PERFORM dropUser('TestUser1');
  PERFORM dropUser('TestUser2');

  --Check that the users were successfully dropped
  IF NOT (pg_temp.checkIfDropped('testUser0')
     AND  pg_temp.checkIfDropped('testUser1')
     AND  pg_temp.checkIfDropped('testUser2')) 
  THEN
    RETURN 'Fail Code 7';
  END IF;

  RETURN 'Passed'

END;
$$ LANGUAGE plpgsql;



--This function tests the changeUsername function. This function creates 3 test
-- accounts and then changes their name. It then checks to make sure that
-- the new username exists.
CREATE OR REPLACE FUNCTION pg_temp.changeUsernameTest() RETURNS TEXT AS
$$
BEGIN

  --Make sure that the roles don't exist already. If they do make sure they are
  -- dropped.
  DROP ROLE IF EXISTS testuser0;
  DROP ROLE IF EXISTS testuser1;
  DROP ROLE IF EXISTS testuser2;


  --Create user with basic privileges 
  PERFORM createUser('testUser0', 'Test user 0', 'testPass0',
                     '7a92db10c4cb11e8b5680800200c9a66', 
                     'testUser0@testemail.com');
  --Create user with teacher privileges 
  PERFORM createUser('testUser1', 'Test user 1', 'testPass1',
                     '9f40a820c4cb11e8b5680800200c9a66',
                     'testUser1@testemail.com', true);

    --Create user with teacher and admin privileges 
  PERFORM createUser('testUser2', 'Test user 2', 'testPass2',
                     'b57810b0c4cb11e8b5680800200c9a66',
                     'testUser2@testemail.com', true, true);

  --Change all usernames 
  LearnSQL.changeUsername('testUser0', 'testUser3');
  LearnSQL.changeUsername('testUser1', 'testUser4');
  LearnSQL.changeUsername('testUser2', 'testUser5');

  --Check if the username was changed
  IF NOT (pg_temp.checkIfUsernameExists('testUser3')
     AND  pg_temp.checkIfUsernameExists('testUser4')
     AND  pg_temp.checkIfUsernameExists('testUser5')) 
  THEN
    RETURN 'Fail Code 1';
  END IF;

  --Check if the previous usernames still exist
  IF (pg_temp.checkIfUsernameExists('testUser0')
     AND  pg_temp.checkIfUsernameExists('testUser1')
     AND  pg_temp.checkIfUsernameExists('testUser2')) 
  THEN
    RETURN 'Fail Code 2';
  END IF;

  RETURN 'Passed'

END;
$$ LANGUAGE plpgsql;



--This function tests the changePassword function. This function creates 3 test
-- accounts and then changes their Password. It then checks to make sure that
-- the password exists in the Userdata_t table.
CREATE OR REPLACE FUNCTION pg_temp.changePasswordTest() RETURNS TEXT AS
$$
BEGIN

  --Make sure that the roles don't exist already. If they do make sure they are
  -- dropped.
  DROP ROLE IF EXISTS testuser0;
  DROP ROLE IF EXISTS testuser1;
  DROP ROLE IF EXISTS testuser2;


    --Create user with basic privileges 
  PERFORM createUser('testUser0', 'Test user 0', 'testPass0',
                     '7a92db10c4cb11e8b5680800200c9a66', 
                     'testUser0@testemail.com');
  --Create user with teacher privileges 
  PERFORM createUser('testUser1', 'Test user 1', 'testPass1',
                     '9f40a820c4cb11e8b5680800200c9a66',
                     'testUser1@testemail.com', true);

    --Create user with teacher and admin privileges 
  PERFORM createUser('testUser2', 'Test user 2', 'testPass2',
                     'b57810b0c4cb11e8b5680800200c9a66',
                     'testUser2@testemail.com', true, true);

  --Change all usernames 
  LearnSQL.changePassword('testUser0', 'testPass0', 'newPass0');
  LearnSQL.changePassword('testUser1', 'testPass1', 'newPass1');
  LearnSQL.changePassword('testUser2', 'testPass2', 'newPass2');

  --Check if the username was changed
  IF NOT (pg_temp.checkPassword('testUser1', 'newPass0')
     AND  pg_temp.checkPassword('testUser2', 'newPass1')
     AND  pg_temp.checkPassword('testUser3', 'newPass2')) 
  THEN
    RETURN 'Fail Code 1';
  END IF;

  RETURN 'Passed'

END;
$$ LANGUAGE plpgsql;



--This function tests the changeFullName function. This function creates 3 test
-- accounts and then changes their Full Name. It then checks to make sure that
-- the FullName exists in the Userdata_t table for that given user.
CREATE OR REPLACE FUNCTION pg_temp.changeFullNameTest() RETURNS TEXT AS
$$
BEGIN

  --Make sure that the roles don't exist already. If they do make sure they are
  -- dropped.
  DROP ROLE IF EXISTS testuser0;
  DROP ROLE IF EXISTS testuser1;
  DROP ROLE IF EXISTS testuser2;


    --Create user with basic privileges 
  PERFORM createUser('testUser0', 'Test user 0', 'testPass0',
                     '7a92db10c4cb11e8b5680800200c9a66', 
                     'testUser0@testemail.com');
  --Create user with teacher privileges 
  PERFORM createUser('testUser1', 'Test user 1', 'testPass1',
                     '9f40a820c4cb11e8b5680800200c9a66',
                     'testUser1@testemail.com', true);

    --Create user with teacher and admin privileges 
  PERFORM createUser('testUser2', 'Test user 2', 'testPass2',
                     'b57810b0c4cb11e8b5680800200c9a66',
                     'testUser2@testemail.com', true, true);
  --Change all usernames 
  LearnSQL.changeFullName('testUser0', 'New Full Name 0');
  LearnSQL.changeFullName('testUser1', 'New Full Name 1');
  LearnSQL.changeFullName('testUser2', 'New Full Name 2');

  --Check if the username was changed
  IF NOT (pg_temp.checkFullName('testUser0', 'New Full Name 0')
     AND  pg_temp.checkFullName('testUser1', 'New Full Name 1')
     AND  pg_temp.checkFullName('testUser2', 'New Full Name 2')) 
  THEN
    RETURN 'Fail Code 1';
  END IF;

  RETURN 'Passed'

END;
$$ LANGUAGE plpgsql;



--This function tests the changeEmail function. This function creates 3 test
-- accounts and then changes their Email. It then checks to make sure that
-- the Email exists in the Userdata_t table for that user.
CREATE OR REPLACE FUNCTION pg_temp.changeEmailTest() RETURNS TEXT AS
$$
BEGIN

  --Make sure that the roles don't exist already. If they do make sure they are
  -- dropped.
  DROP ROLE IF EXISTS testuser0;
  DROP ROLE IF EXISTS testuser1;
  DROP ROLE IF EXISTS testuser2;


    --Create user with basic privileges 
  PERFORM createUser('testUser0', 'Test user 0', 'testPass0',
                     '7a92db10c4cb11e8b5680800200c9a66', 
                     'testUser0@testemail.com');
  --Create user with teacher privileges 
  PERFORM createUser('testUser1', 'Test user 1', 'testPass1',
                     '9f40a820c4cb11e8b5680800200c9a66',
                     'testUser1@testemail.com', true);

    --Create user with teacher and admin privileges 
  PERFORM createUser('testUser2', 'Test user 2', 'testPass2',
                     'b57810b0c4cb11e8b5680800200c9a66',
                     'testUser2@testemail.com', true, true);

  --Change all usernames 
  LearnSQL.changeEmail('testUser0', 'newEmail0@testemail.com');
  LearnSQL.changeEmail('testUser1', 'newEmail1@testemail.com');
  LearnSQL.changeEmail('testUser2', 'newEmail2@testemail.com');

  --Check if the username was changed
  IF NOT (pg_temp.checkEmail('testUser0', 'newEmail0@testemail.com')
     AND  pg_temp.checkEmail('testUser1', 'newEmail1@testemail.com')
     AND  pg_temp.checkEmail('testUser2', 'newEmail2@testemail.com')) 
  THEN
    RETURN 'Fail Code 1';
  END IF;

  RETURN 'Passed'

END;
$$ LANGUAGE plpgsql;



--This function tests the forgotPasswordReset function. This function creates 3 test
-- accounts and then resets thier password with forgotPasswordReset Function.
-- It then checks to make sure that the Email exists in the Userdata_t table for that user.
CREATE OR REPLACE FUNCTION pg_temp.forgotPasswordResetTest() RETURNS TEXT AS
$$
BEGIN

  --Make sure that the roles don't exist already. If they do make sure they are
  -- dropped.
  DROP ROLE IF EXISTS testuser0;
  DROP ROLE IF EXISTS testuser1;
  DROP ROLE IF EXISTS testuser2;


    --Create user with basic privileges 
  PERFORM createUser('testUser0', 'Test user 0', 'testPass0',
                     '7a92db10c4cb11e8b5680800200c9a66', 
                     'testUser0@testemail.com');
  --Create user with teacher privileges 
  PERFORM createUser('testUser1', 'Test user 1', 'testPass1',
                     '9f40a820c4cb11e8b5680800200c9a66',
                     'testUser1@testemail.com', true);

    --Create user with teacher and admin privileges 
  PERFORM createUser('testUser2', 'Test user 2', 'testPass2',
                     'b57810b0c4cb11e8b5680800200c9a66',
                     'testUser2@testemail.com', true, true);

  --Change all usernames 
  LearnSQL.forgotPasswordReset('testUser0', '7a92db10c4cb11e8b5680800200c9a66', 
                               'newPass0');
  LearnSQL.forgotPasswordReset('testUser1', '9f40a820c4cb11e8b5680800200c9a66',
                               'newPass1');
  LearnSQL.forgotPasswordReset('testUser2', 'b57810b0c4cb11e8b5680800200c9a66', 
                               'newPass2');

  --Check if the username was changed
  IF NOT (pg_temp.checkPassword('testUser1', 'newPass0')
     AND  pg_temp.checkPassword('testUser2', 'newPass1')
     AND  pg_temp.checkPassword('testUser3', 'newPass2')) 
  THEN
    RETURN 'Fail Code 1';
  END IF;

  RETURN 'Passed'

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



--ignore all test data
ROLLBACK;