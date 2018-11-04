-- testStudentMgmt.sql - LearnSQL

-- Christopher Innaco
-- Web Applications and Databases for Education (WADE)

-- This file tests the functions involved with student management in the LearnSQL
--  database

START TRANSACTION;

--Suppress NOTICEs for this script only, this will not apply to functions
-- defined within. This hides unimportant, and possibly confusing messages
SET LOCAL client_min_messages TO WARNING;

-- Set maximum verbosity to determine SQLSTATE codes if needed
\set VERBOSITY verbose

--Make sure the current user has sufficient privilege to run this script
-- Privilege required: SUPERUSER

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
*   Creates a database user with the attributes `SUPERUSER` 
*    and `classdb_admin`. All testing functions which require
*    a database user will use the username and password
*    provided as a parameter.
*/
CREATE OR REPLACE FUNCTION
  pg_temp.createTempDBUser(userName  LearnSQL.UserData_t.userName%Type,
                            password  LearnSQL.UserData_t.password%Type)
  RETURNS VOID AS
$$
BEGIN

  EXECUTE FORMAT('CREATE USER %s WITH PASSWORD %L CREATEDB', $1, $2);

  EXECUTE FORMAT('ALTER USER %s WITH SUPERUSER;', $1);

  EXECUTE FORMAT('GRANT CONNECT ON DATABASE LearnSQL TO %s', $1);

  EXECUTE FORMAT('GRANT classdb_admin TO %s', $1);

END;
$$ LANGUAGE plpgsql;



/*
*   Drops the database user and dependent database owned by the user
*    Reassigns owner of the template database back to `classdb`
*/
CREATE OR REPLACE FUNCTION
  pg_temp.dropTempDBUser(userName  LearnSQL.UserData_t.userName%Type,
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
  FROM LearnSQL.dblink('user='      || $1 || 
                       ' password=' || $2 || 
                       ' dbname=learnsql', dropDBQuery)
  AS throwAway(blank VARCHAR(30));

  EXECUTE FORMAT('REVOKE classdb_admin FROM %s', $1);

  EXECUTE FORMAT('REVOKE CONNECT ON DATABASE LearnSQL FROM %s', $1);

  EXECUTE FORMAT('DROP USER %s', $1);

END;
$$ LANGUAGE plpgsql;



/*
*   Returns the hashed password of a user
*/
CREATE OR REPLACE FUNCTION
  pg_temp.getUserHashedPassword(userName LearnSQL.Userdata_t.userName%Type)
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
CREATE OR REPLACE FUNCTION
  pg_temp.getClassHashedPassword(classID LearnSQL.Class_t.classID%Type)
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
CREATE OR REPLACE FUNCTION
  pg_temp.addTestUsers()
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

END;
$$ LANGUAGE plpgsql;



/* 
*  Define a temporary function to delete the user in userdata_t table and the
*   database role without the need of a database password.
*   Should only be used to clean up at the end of test functions.
*/ 
CREATE OR REPLACE FUNCTION
  pg_temp.dropUser(userName  LearnSQL.UserData_t.UserName%Type)
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



/*
*   Removes test users after 
*/
CREATE OR REPLACE FUNCTION
  pg_temp.dropTestUsers()
  RETURNS VOID AS
$$
BEGIN

  /*DELETE FROM learnsql.attends WHERE username LIKE 'test%';
  DELETE FROM learnsql.userdata_t WHERE username LIKE 'test%';
  DELETE FROM learnsql.class_t WHERE classid LIKE 'cs305%';*/
  PERFORM LearnSQL.dropClass('test_dbuser', 'testPassword', 
                             'testteacher', 'CS305', '71', '2018-8-28');

  PERFORM pg_temp.dropUser('testuser0');
  PERFORM pg_temp.dropUser('testuser1');
  PERFORM pg_temp.dropUser('testteacher');
  PERFORM pg_temp.dropUser('testadmin');

END;
$$ LANGUAGE plpgsql;



/*
*   Function which calls the joinClass function
*    to add students to a class
*/
CREATE OR REPLACE FUNCTION
  pg_temp.joinClassTest(databaseUsername  VARCHAR(63),
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



/*
*   Gives ClassDB-level administrator privileges to the test administrator 
*/
CREATE OR REPLACE FUNCTION
  pg_temp.grantAdministrator(userName  LearnSQL.UserData_t.UserName%Type,
                             databaseUsername  VARCHAR(63),
                             databasePassword  VARCHAR(64))
  RETURNS VOID AS
$$
DECLARE

  grantAdminQuery TEXT;

  classID LearnSQL.Class_t.classID%Type;

BEGIN

  SELECT INTO classID LearnSQL.getClassID('testteacher', 'CS305', '71', '2018-8-28');

  grantAdminQuery := ' SELECT ClassDB.grantRole(''classdb_admin'','''|| $1 ||''') '; 

  PERFORM *
  FROM LearnSQL.dblink('user='      || $2 || 
                       ' password=' || $3 || 
                       ' dbname=  ' || classID, grantAdminQuery)
  AS throwAway(blank VARCHAR(30));
  

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
CREATE OR REPLACE FUNCTION
  pg_temp.recordTestEvent(eventTime         pg_temp.ErrorLog.EventTime%Type,
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
    ELSE
      PERFORM pg_temp.recordTestEvent(currentTimestamp, 'createTempDBUser()', FALSE, 'Failed to create database user');
  END IF;

END;
$$ LANGUAGE plpgsql;


/*
*   Checks if the four expected test users exist in the table
*/
CREATE OR REPLACE FUNCTION
  pg_temp.checkTestUsers()
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
  WHERE userName LIKE 'test%';

  IF testUserCount = 4
    THEN  
      PERFORM pg_temp.recordTestEvent(currentTimestamp, 'addTestUsers()', TRUE);
    ELSE
      PERFORM pg_temp.recordTestEvent(currentTimestamp, 'addTestUsers()', FALSE, 'Failed to add test users');
  END IF;

END;
$$ LANGUAGE plpgsql;


/*
*   Checks if the LearnSQL class table and database exist
*/
CREATE OR REPLACE FUNCTION
  pg_temp.checkClassCreation(teacherName  LearnSQL.Attends.UserName%Type,
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
    ELSE
      PERFORM pg_temp.recordTestEvent(currentTimestamp, 'createClass()', FALSE, 'Failed to create class database and LearnSQL table entry');
  END IF;

END;
$$ LANGUAGE plpgsql;


/*
*   Checks if the administrator test user was granted the correct rights
*/
CREATE OR REPLACE FUNCTION
  pg_temp.checkAdministrator(adminUserName  LearnSQL.Attends.UserName%Type,
                             databaseUsername  VARCHAR(63),
                             databasePassword  VARCHAR(64),
                             teacherName  LearnSQL.Attends.UserName%Type,
                             className    LearnSQL.Class_t.ClassName%Type,
                             classSection LearnSQL.Class_t.Section%Type,
                             startDate    LearnSQL.Class_t.StartDate%Type)
  RETURNS VOID AS
$$
DECLARE
  checkAdminQuery   TEXT;
  currentTimestamp  TIMESTAMP;
  storedClassID     LearnSQL.Class_t.classID%Type;
  isAdmin           BOOLEAN;
    
BEGIN

  isAdmin := FALSE;

  SELECT INTO storedClassID LearnSQL.getClassID($4, $5, $6, $7);

  currentTimestamp := CURRENT_TIMESTAMP;

  checkAdminQuery := ' SELECT ClassDB.isMember('''|| adminUserName ||''', ''classdb_admin'') ';

  SELECT *
  INTO isAdmin
  FROM LearnSQL.dblink('user='      || $2 || 
                       ' password=' || $3 || 
                       ' dbname='   || storedClassID, checkAdminQuery)
  AS throwAway(blank VARCHAR(30)); -- Unused return variable for `dblink`

  IF isAdmin IS TRUE
    THEN  
      PERFORM pg_temp.recordTestEvent(currentTimestamp, 'grantAdministrator()', TRUE);
    ELSE
      PERFORM pg_temp.recordTestEvent(currentTimestamp, 'grantAdministrator()', FALSE, 'Failed to grant administrator permissions to test admin user');
  END IF;

END;
$$ LANGUAGE plpgsql;



/*
*   Checks if the users given in the parameters are members of a given class
*/
CREATE OR REPLACE FUNCTION
  pg_temp.checkClassEnrollment(studentName  LearnSQL.Attends.UserName%Type,
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

  --TODO: Use a crossDB query to check if student in ClassDB.Rolebase table
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
    ELSE
      PERFORM pg_temp.recordTestEvent(currentTimestamp, 'joinClass()', FALSE, 'Failed to enroll student in the specified class');
  END IF;

END;
$$ LANGUAGE plpgsql;



/*
*   Checks if the four expected test users are dropped from the database
*/
CREATE OR REPLACE FUNCTION
  pg_temp.checkDropUsers()
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
  WHERE userName LIKE 'test%';

  --TODO: Check if roles are dropped too

  IF testUserCount = 0
    THEN  
      PERFORM pg_temp.recordTestEvent(currentTimestamp, 'dropTestUsers()', TRUE);
    ELSE
      PERFORM pg_temp.recordTestEvent(currentTimestamp, 'dropTestUsers()', FALSE, 'Failed to drop test users');
  END IF;

END;
$$ LANGUAGE plpgsql;



/*
*   Checks if a temporary database user was dropped
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

  IF existsDBUser IS FALSE
    THEN  
      PERFORM pg_temp.recordTestEvent(currentTimestamp, 'dropTempDBUser()', 'TRUE', NULL);
    ELSE
      PERFORM pg_temp.recordTestEvent(currentTimestamp, 'dropTempDBUser()', FALSE, 'Failed to drop database user');
  END IF;

END;
$$ LANGUAGE plpgsql;


COMMIT;

TRUNCATE pg_temp.ErrorLog;

SELECT pg_temp.createTempDBUser('test_dbuser', 'testPassword');
SELECT pg_temp.checkTempDBUser('test_dbuser');

SELECT pg_temp.addTestUsers();
SELECT pg_temp.checkTestUsers();

SELECT LearnSQL.createClass('test_dbuser', 'testPassword', 'testteacher', 
                            'classPassword', 'CS305', '71', '5:30 - 7:10', 
                            'TR', '2018-8-28', '2018-12-13');
SELECT pg_temp.checkClassCreation('testteacher', 'CS305', '71', '2018-8-28');

SELECT pg_temp.grantAdministrator('testadmin', 'test_dbuser', 'testPassword');
SELECT pg_temp.checkAdministrator('testadmin', 'test_dbuser', 'testPassword', 'testteacher', 'CS305', '71', '2018-8-28');

SELECT pg_temp.joinClassTest('test_dbuser', 'testPassword');
SELECT pg_temp.checkClassEnrollment('testuser0','testteacher', 'CS305', '71', '2018-8-28');
SELECT pg_temp.checkClassEnrollment('testuser1','testteacher', 'CS305', '71', '2018-8-28');

SELECT pg_temp.dropTestUsers();
SELECT pg_temp.checkDropUsers();

SELECT pg_temp.dropTempDBUser('test_dbuser', 'testPassword');
SELECT pg_temp.checkTempDBUser('test_dbuser');

SELECT '`testStudentMgmt.sql` Automated Test Results';
SELECT eventTime, functionName, isTestSuccessful, errorDescription
FROM pg_temp.ErrorLog;

--TODO: Add function and test to drop class's DB
