-- testStudentMgmt.sql - LearnSQL

-- Christopher Innaco
-- Web Applications and Databases for Education (WADE)

-- This file tests the functions involved with student enrollment in classes

START TRANSACTION;

-- Suppress NOTICEs for this script only, this will not apply to functions
--  defined within. This hides unimportant, and possibly confusing messages
SET LOCAL client_min_messages TO WARNING;

-- Make sure the current user has sufficient privilege to run this script
--  Privilege required: SUPERUSER

DO
$$
BEGIN
  IF NOT EXISTS (
                  SELECT 1 FROM pg_catalog.pg_roles
                  WHERE rolname = CURRENT_USER AND rolsuper = TRUE
                ) 
    THEN
      RAISE EXCEPTION 'Insufficient privileges: User must hold superuser '
                      'permissions to execute this script';
   END IF;
END
$$;



/*
*   Create a table to store data about test results
*/
CREATE TABLE IF NOT EXISTS pg_temp.ErrorLog (
  eventTime               TIMESTAMP NOT NULL,
  functionName            VARCHAR(256) NOT NULL,
  isTestSuccessful        BOOLEAN DEFAULT FALSE,
  errorDescription        VARCHAR(256) DEFAULT NULL,
  PRIMARY KEY (eventTime, functionName, isTestSuccessful)
);



/*
*   Creates a database user with the permissions `SUPERUSER` 
*    and `classdb_admin`. All testing functions which require
*    a database user will use the username and password
*    provided as a parameter.
*/
CREATE OR REPLACE FUNCTION pg_temp.createTempDBUser(
    userName  LearnSQL.UserData_t.userName%Type,
    password  LearnSQL.UserData_t.password%Type)
  RETURNS VOID AS

$$
BEGIN

  EXECUTE FORMAT('CREATE USER %s WITH PASSWORD %L CREATEDB CREATEROLE', $1, $2);

  EXECUTE FORMAT('ALTER USER %s WITH SUPERUSER;', $1);

  EXECUTE FORMAT('GRANT CONNECT ON DATABASE LearnSQL TO %s', $1);

  EXECUTE FORMAT('GRANT classdb_admin TO %s', $1);

END;
$$ LANGUAGE plpgsql;



/*
*   Drops the database user and dependent database owned by the user
*/
CREATE OR REPLACE FUNCTION pg_temp.dropTempDBUser(
    userName  LearnSQL.UserData_t.userName%Type,
    password  LearnSQL.UserData_t.password%Type)
  RETURNS VOID AS

$$
DECLARE

  dbName      TEXT;
  dropDBQuery TEXT;

BEGIN

  SELECT datname
  INTO dbName
  FROM pg_database
  WHERE pg_database.datname LIKE 'cs305%';

  dropDBQuery := 'DROP DATABASE ' || dbName; 

  PERFORM *
  FROM LearnSQL.dblink_exec('user='      || $1 || 
                           ' password=' || $2 || 
                           ' dbname=learnsql', dropDBQuery);

  EXECUTE FORMAT('REVOKE classdb_admin FROM %s', $1);

  EXECUTE FORMAT('REVOKE CONNECT ON DATABASE LearnSQL FROM %s', $1);

  EXECUTE FORMAT('DROP USER %s', $1);

END;
$$ LANGUAGE plpgsql;



/*
*   Returns the hashed password of a user
*/
CREATE OR REPLACE FUNCTION pg_temp.getUserHashedPassword(
    userName LearnSQL.Userdata_t.userName%Type)
  RETURNS VARCHAR AS

$$
DECLARE

  hashedPassword  LearnSQL.Userdata_t.password%Type;

BEGIN

  SELECT password 
  INTO hashedPassword 
  FROM LearnSQL.Userdata_t 
  WHERE LearnSQL.Userdata_t.userName = $1;

RETURN hashedPassword;
  
END;
$$ LANGUAGE plpgsql;



/*
*   Returns the hashed password of a class
*/
CREATE OR REPLACE FUNCTION pg_temp.getClassHashedPassword(
    classID LearnSQL.Class_t.classID%Type)
  RETURNS VARCHAR AS

$$
DECLARE

  hashedPassword  LearnSQL.Class_t.password%Type;

BEGIN

  SELECT password 
  INTO hashedPassword 
  FROM LearnSQL.Class_t 
  WHERE LearnSQL.Class_t.classID = $1;

RETURN hashedPassword;
  
END;
$$ LANGUAGE plpgsql;



/*
*   Function creates test users of varying privilege levels
*/
CREATE OR REPLACE FUNCTION pg_temp.addTestUsers()
  RETURNS VOID AS

$$
BEGIN

  -- Create user with basic privileges 
  PERFORM LearnSQL.createUser('testuser0', 'Test User 0', 'testPass0',
                              'testUser@testemail.com',
                              '7a92db10c4cb11e8b5680800200c9a66');

  -- Create user with basic privileges 
  PERFORM LearnSQL.createUser('testuser1', 'Test User 1', 'testPass1',
                              'testUser1@testemail.com',
                              '$2a$06$zgCsfQhVwzaSWFswiK.27uLZv');

  -- Create user with teacher privileges 
  PERFORM LearnSQL.createUser('testteacher', 'Test Teacher', 'testPass2',
                              'testTeacher@testemail.com',
                              '9f40a820c4cb11e8b5680800200c9a66', TRUE);

  -- Create user with administrator privileges 
  PERFORM LearnSQL.createUser('testadmin', 'Test Admin', 'testPass3',
                              'testAdmin@testemail.com',
                              'b57810b0c4cb11e8b5680800200c9a66', FALSE, TRUE);
  EXECUTE FORMAT('GRANT classdb_admin TO testAdmin');
  EXECUTE FORMAT('GRANT CONNECT ON DATABASE LearnSQL TO testadmin');

END;
$$ LANGUAGE plpgsql;



/* 
*  Define a temporary function to delete the user in userdata_t table and the
*   database role without the need of a database password.
*   Should only be used to clean up at the end of test functions.
*/ 
CREATE OR REPLACE FUNCTION pg_temp.dropUser(
    userName  LearnSQL.UserData_t.UserName%Type)
  RETURNS VOID AS

$$
BEGIN
  -- Delete user from LearnSQL tables
  DELETE FROM LearnSQL.UserData_t WHERE UserData_t.Username = $1;

  -- Check if username is a postgres rolename and if so, delete
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



/*
*   Removes test users after 
*/
CREATE OR REPLACE FUNCTION pg_temp.dropTestUsers()
  RETURNS VOID AS

$$
BEGIN

  PERFORM pg_temp.dropUser('testuser0');
  PERFORM pg_temp.dropUser('testuser1');
  PERFORM pg_temp.dropUser('testteacher');
  REVOKE CONNECT ON DATABASE LearnSQL FROM testadmin;
  PERFORM pg_temp.dropUser('testadmin');

END;
$$ LANGUAGE plpgsql;



/*
*   Function which calls the joinClass function
*    to add students to a class
*/
CREATE OR REPLACE FUNCTION pg_temp.joinClassTest(
    databaseUsername  VARCHAR(63),
    databasePassword  VARCHAR(64))
  RETURNS VOID AS

$$
DECLARE

  classID LearnSQL.Class_t.classID%Type;

BEGIN

  SELECT INTO classID LearnSQL.getClassID('testteacher', 'CS305', '71', '2018-8-28');
                              
  -- Test if a student can join a class using a class password
  PERFORM LearnSQL.joinClass('testuser0', 'Test User 0', 
                              pg_temp.getUserHashedPassword('testuser0'), 
                              classID, 
                              pg_temp.getClassHashedPassword(classID), 
                              $1, $2);

  -- Test if an administrator can force a student into a class
  PERFORM LearnSQL.joinClass('testuser1', 'Test User 1', 
                              pg_temp.getUserHashedPassword('testuser1'), 
                              classID , NULL , $1, $2, 'testadmin');
  
END;
$$ LANGUAGE plpgsql;



/**************************************************************************************
*
*   Helper functions
*
***************************************************************************************
*/



/*
*   Records the details of a test function event
*/
CREATE OR REPLACE FUNCTION pg_temp.recordTestEvent(
    eventTime         pg_temp.ErrorLog.EventTime%Type,
    functionName      pg_temp.ErrorLog.FunctionName%Type,
    isTestSuccessful  pg_temp.ErrorLog.isTestSuccessful%Type,
    errorDescription  pg_temp.ErrorLog.errorDescription%Type
                      DEFAULT NULL)
  RETURNS VOID AS

$$
BEGIN
      INSERT INTO pg_temp.ErrorLog VALUES($1, $2, $3, $4);
END;
$$ LANGUAGE plpgsql;



/*
*   Checks if a temporary database user exists
*/
CREATE OR REPLACE FUNCTION
  pg_temp.checkTempDBUser(userName  LearnSQL.UserData_t.UserName%Type)
  RETURNS VOID AS
$$
DECLARE

  existsDBUser     BOOLEAN;
  currentTimestamp TIMESTAMP;

BEGIN

  existsDBUser := FALSE;
  currentTimestamp := CURRENT_TIMESTAMP;

  SELECT 1
  INTO existsDBUser
  FROM pg_roles
  WHERE rolname = $1;

  IF existsDBUser IS TRUE
    THEN  
      PERFORM pg_temp.recordTestEvent(currentTimestamp, 'createTempDBUser()', 'TRUE', NULL);
      RETURN;
    ELSE
      PERFORM pg_temp.recordTestEvent(currentTimestamp, 'createTempDBUser()', FALSE, 
                                      'Failed to create database user');
      RETURN;
  END IF;

END;
$$ LANGUAGE plpgsql;



/*
*   Checks if the four expected test users exist in the table
*/
CREATE OR REPLACE FUNCTION pg_temp.checkTestUsers()
  RETURNS VOID AS

$$
DECLARE

  testUserCount INTEGER;
  currentTimestamp TIMESTAMP;

BEGIN

    testUserCount := 0;
    currentTimestamp := CURRENT_TIMESTAMP;

  SELECT COUNT(userName)
  INTO testUserCount
  FROM LearnSQL.UserData_t
  WHERE userName = 'testadmin'
  OR userName = 'testteacher'
  OR userName = 'testuser0'
  OR userName = 'testuser1';

  IF testUserCount = 4
    THEN  
      PERFORM pg_temp.recordTestEvent(currentTimestamp, 'addTestUsers()', TRUE);
      RETURN;
    ELSE
      PERFORM pg_temp.recordTestEvent(currentTimestamp, 'addTestUsers()', FALSE, 
                                      'Failed to add test users');
      RETURN;
  END IF;

END;
$$ LANGUAGE plpgsql;



/*
*   Checks if the LearnSQL class table and database exist
*/
CREATE OR REPLACE FUNCTION pg_temp.checkClassCreation(
    teacherName  LearnSQL.Attends.UserName%Type,
    className    LearnSQL.Class_t.ClassName%Type,
    classSection LearnSQL.Class_t.Section%Type,
    startDate    LearnSQL.Class_t.StartDate%Type)
  RETURNS VOID AS

$$
DECLARE

  existsClassDatabase BOOLEAN;
  existsClassTable    BOOLEAN;
  storedClassID       LearnSQL.Class_t.classID%Type;
  currentTimestamp    TIMESTAMP;

BEGIN

  existsClassDatabase := FALSE;
  existsClassTable    := FALSE;
  currentTimestamp    := CURRENT_TIMESTAMP;

  SELECT INTO storedClassID LearnSQL.getClassID($1, $2, $3, $4);
  
  SELECT 1
  INTO existsClassDatabase
  FROM pg_database
  WHERE datname = LOWER(storedClassID);

  SELECT 1
  INTO existsClassTable
  FROM LearnSQL.Class_t
  WHERE LearnSQL.Class_t.classID = storedClassID;

  IF (existsClassDatabase IS TRUE) AND (existsClassTable IS TRUE)
    THEN  
      PERFORM pg_temp.recordTestEvent(currentTimestamp, 'createClass()', TRUE);
      RETURN;
    ELSE
      PERFORM pg_temp.recordTestEvent(currentTimestamp, 'createClass()', FALSE, 
                                      'Failed to create class database and LearnSQL Class_t entry');
      RETURN;
  END IF;

END;
$$ LANGUAGE plpgsql;



/*
*   Checks if the users given in the parameters are members of a given class
*/
CREATE OR REPLACE FUNCTION pg_temp.checkClassEnrollment(
    studentName  LearnSQL.Attends.UserName%Type,
    teacherName  LearnSQL.Attends.UserName%Type,
    className    LearnSQL.Class_t.ClassName%Type,
    classSection LearnSQL.Class_t.Section%Type,
    startDate    LearnSQL.Class_t.StartDate%Type)
  RETURNS VOID AS

$$
DECLARE

  currentTimestamp  TIMESTAMP;
  isEnrolled        BOOLEAN;
  storedClassID     LearnSQL.Class_t.classID%Type;
    
BEGIN

  isEnrolled := FALSE;
  currentTimestamp := CURRENT_TIMESTAMP;
  SELECT INTO storedClassID LearnSQL.getClassID($2, $3, $4, $5);

  SELECT 1
  INTO isEnrolled
  FROM LearnSQL.Attends
  WHERE LearnSQL.Attends.classID = storedClassID
  AND LearnSQL.Attends.userName = $1;


  IF isEnrolled IS TRUE
    THEN  
      PERFORM pg_temp.recordTestEvent(currentTimestamp, 'joinClass()', TRUE);
      RETURN;
    ELSE
      PERFORM pg_temp.recordTestEvent(currentTimestamp, 'joinClass()', FALSE, 
                                      'Failed to enroll student in the specified class');
      RETURN;
  END IF;

END;
$$ LANGUAGE plpgsql;



/*
*   Checks if the four expected test users are dropped from the database
*/
CREATE OR REPLACE FUNCTION pg_temp.checkDropUsers()
  RETURNS VOID AS

$$
DECLARE

  testUserDBCount   INTEGER;
  testUserRoleCount INTEGER;
  currentTimestamp  TIMESTAMP;

BEGIN

    testUserDBCount := 0;
    testUserRoleCount := 0;
    currentTimestamp := CURRENT_TIMESTAMP;

  -- Check if the users exist in the LearnSQL Userdata_t table
  SELECT COUNT(userName)
  INTO testUserDBCount
  FROM LearnSQL.UserData_t
  WHERE userName = 'testadmin'
  OR userName = 'testteacher'
  OR userName = 'testuser0'
  OR userName = 'testuser1';

  -- Check if the roles have been dropped from the server
  SELECT COUNT(rolname)
  INTO testUserRoleCount
  FROM pg_roles
  WHERE rolname = 'testadmin'
  OR rolname = 'testteacher'
  OR rolname = 'testuser0'
  OR rolname = 'testuser1';

  IF testUserDBCount = 0 AND testUserRoleCount = 0
    THEN  
      PERFORM pg_temp.recordTestEvent(currentTimestamp, 'dropTestUsers()', TRUE);
      RETURN;
    ELSE
      PERFORM pg_temp.recordTestEvent(currentTimestamp, 'dropTestUsers()', FALSE, 
                                      'Failed to drop test users');
      RETURN;
  END IF;

END;
$$ LANGUAGE plpgsql;



/*
*   Checks if the temporary database user exists.
*    When `mode` is set, the userName is expected to exist. Otherwise,
*    it is expected the user was dropped before calling this function.
*/
CREATE OR REPLACE FUNCTION pg_temp.checkTempDBUser(
    userName  LearnSQL.UserData_t.UserName%Type,
    mode      BOOLEAN)
  RETURNS VOID AS

$$
DECLARE

  existsDBUser     BOOLEAN;
  currentTimestamp TIMESTAMP;

BEGIN

  existsDBUser := FALSE;
  currentTimestamp := CURRENT_TIMESTAMP;

  SELECT 1
  INTO existsDBUser
  FROM pg_roles
  WHERE rolname = $1;

  IF $2 IS TRUE
    THEN

    IF existsDBUser IS TRUE 
      THEN  
        PERFORM pg_temp.recordTestEvent(currentTimestamp, 'dropTempDBUser(TRUE)', 'TRUE', NULL);
        RETURN;
      ELSE
        PERFORM pg_temp.recordTestEvent(currentTimestamp, 'dropTempDBUser(TRUE)', FALSE, 
                                        'Failed to create database user');
        RETURN;
    END IF;

    ELSE -- If $2 is false

    IF existsDBUser IS NULL
      THEN  
        PERFORM pg_temp.recordTestEvent(currentTimestamp, 'dropTempDBUser(FALSE)', 'TRUE', NULL);
        RETURN;
    ELSE
        PERFORM pg_temp.recordTestEvent(currentTimestamp, 'dropTempDBUser(FALSE)', FALSE, 
                                        'Failed to drop database user');
        RETURN;
    END IF;

  END IF;

END;
$$ LANGUAGE plpgsql;


/* 
*   Returns the results of the function calls in this script which
*    test the facilities provided in the `studentMgmt.sql` script
*/
CREATE OR REPLACE FUNCTION pg_temp.getTestResults()
  RETURNS TABLE (
                  eventTime         pg_temp.ErrorLog.eventTime%Type,
                  functionName      pg_temp.ErrorLog.functionName%Type,
                  isTestSuccessful  pg_temp.ErrorLog.isTestSuccessful%Type,
                  errorDescription  pg_temp.ErrorLog.errorDescription%Type
                ) 
  AS

$$
BEGIN

  RAISE INFO '`testStudentMgmt.sql` Automated Test Results';

  RETURN QUERY
  SELECT pg_temp.ErrorLog.eventTime, 
         pg_temp.ErrorLog.functionName, 
         pg_temp.ErrorLog.isTestSuccessful, 
         pg_temp.ErrorLog.errorDescription
  FROM pg_temp.ErrorLog;

END;
$$ LANGUAGE plpgsql;


COMMIT;

-- Erase the error log upon every call of this script
TRUNCATE pg_temp.ErrorLog;

SELECT pg_temp.createTempDBUser('test_dbuser', 'testPassword');
SELECT pg_temp.checkTempDBUser('test_dbuser', TRUE);

SELECT pg_temp.addTestUsers();
SELECT pg_temp.checkTestUsers();

SELECT LearnSQL.createClass('test_dbuser', 'testPassword', 'testteacher', 
                            'classPassword', 'CS305', '71', '5:30 - 7:10', 
                            'TR', '2018-8-28', '2018-12-13');
SELECT pg_temp.checkClassCreation('testteacher', 'CS305', '71', '2018-8-28');
SELECT pg_temp.checkClassEnrollment('testteacher','testteacher', 'CS305', '71', '2018-8-28');
SELECT * FROM LearnSQL.getClasses('testteacher');

SELECT pg_temp.joinClassTest('test_dbuser', 'testPassword');
SELECT pg_temp.checkClassEnrollment('testuser0','testteacher', 'CS305', '71', '2018-8-28');
SELECT * FROM LearnSQL.getClasses('testuser0');
SELECT pg_temp.checkClassEnrollment('testuser1','testteacher', 'CS305', '71', '2018-8-28');
SELECT * FROM LearnSQL.getClasses('testuser1');

SELECT LearnSQL.dropClass('test_dbuser', 'testPassword', 
                          'testteacher', 'CS305', '71', '2018-8-28');

SELECT pg_temp.dropTestUsers();
SELECT pg_temp.checkDropUsers();

SELECT pg_temp.dropTempDBUser('test_dbuser', 'testPassword');
SELECT pg_temp.checkTempDBUser('test_dbuser', FALSE);

SELECT * FROM pg_temp.getTestResults();
