-- testClassMgmt.sql - LearnSQL

-- Michael Torres
-- Web Applications and Databases for Education (WADE)

-- This file tests the functions involved with class management in the LearnSQL
--  database.



START TRANSACTION;

-- Suppress NOTICES for this script only, this will not apply to functions
--  defined within. This hides unimportant, but possibly confusing messages.
SET LOCAL client_min_messages TO WARNING;

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



-- Create a user with privilege for CREATEDB which will be used for testing.
CREATE USER testadminuser WITH PASSWORD 'password' CREATEDB CREATEROLE;
GRANT CONNECT ON DATABASE LearnSQL TO testadminuser;
GRANT classdb_admin TO testadminuser;



-- Users are created here separate from the transaction below to not cause 
--  errors with dblink.
SELECT LearnSQL.createUser('testuser1', 'first last', '123', 
                           'testUser1@testemail.com', 
                           '7a92db10c4cb11e8b5680800200c9a66', true);
SELECT LearnSQL.createUser('testuser2', 'first last', '123', 
                           'testUser2@testemail.com', 
                           '9f40a820c4cb11e8b5680800200c9a66', true);
SELECT LearnSQL.createUser('testuser3', 'first last', '123', 
                           'testUser3@testemail.com', 
                           'b57810b0c4cb11e8b5680800200c9a66', true);

COMMIT;



START TRANSACTION;

/*------------------------------------------------------------------------------
    Define Temporary helper functions for assisting testClassMgmt functions
------------------------------------------------------------------------------*/

-- This function checks if the class's database exists and if the class exists
--  LearnSQL tables.
CREATE OR REPLACE FUNCTION
  pg_temp.checkIfClassIdExists(classid LearnSQL.Class_t.ClassID%Type)
  RETURNS BOOLEAN AS 
$$
BEGIN 
  -- Check if the class exists in the PostgreSQL database.
  IF NOT EXISTS (
                  SELECT 1 
                  FROM pg_database
                  WHERE datname = $1
                )
  THEN
    RETURN FALSE;
  END IF;

  -- Check if the class exists in the LearnSQL Attends table.
  IF NOT EXISTS (
                  SELECT 1 
                  FROM LearnSQL.Attends
                  WHERE Attends.classid = $1
                )
  THEN 
    RETURN FALSE;
  END IF;

  -- Check if the class exists in the LearnSQL Class_t table.
  IF EXISTS (
              SELECT 1 
              FROM LearnSQL.Class_t
              WHERE Class_t.classid = $1
            )
  THEN 
    RETURN TRUE;
  ELSE 
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;



-- This function checks if the class name exists.
CREATE OR REPLACE FUNCTION
  pg_temp.checkIfClassNameExists(className LearnSQL.Class_t.ClassName%Type,
                                 classid   LearnSQL.Class_t.ClassID%Type)
  RETURNS BOOLEAN AS 
$$
BEGIN
  -- Check if the class name exists given the class id.
  IF EXISTS (
              SELECT 1
              FROM LearnSQL.Class_t
              WHERE Class_t.className = $1
              AND Class_t.classid = $2
            )
  THEN
    RETURN TRUE;
  ELSE 
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;



-- This function defines whether the class has a corresponding section.
CREATE OR REPLACE FUNCTION 
  pg_temp.checkIfClassSectionExists(classSection LearnSQL.Class_t.Section%Type,
                                    classid      LearnSQL.Class_t.ClassID%Type)
  RETURNS BOOLEAN AS 
$$ 
BEGIN 
  -- Check if section exists given the class id for the class.
  IF EXISTS (
              SELECT 1 
              FROM LearnSQL.Class_t
              WHERE Class_t.section = $1
              AND Class_t.classid = $2
            )
  THEN 
    RETURN TRUE;
  ELSE 
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;



-- This function defines whether the class has a time to it.
CREATE OR REPLACE FUNCTION
  pg_temp.checkIfClassTimeExists(classTimes LearnSQL.Class_t.Times%Type,
                                 classid    LearnSQL.Class_t.ClassID%Type)
  RETURNS BOOLEAN AS 
$$ 
BEGIN 
  -- Check if a time exists given the class id for the class.
  IF EXISTS (
              SELECT 1 
              FROM LearnSQL.Class_t
              WHERE Class_t.times = $1
              AND Class_t.classid = $2
            )
  THEN 
    RETURN TRUE;
  ELSE 
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;



-- This function defines whether the class has the days in which it runs.
CREATE OR REPLACE FUNCTION
  pg_temp.checkIfClassDaysExists(classDays LearnSQL.Class_t.Days%Type,
                                 classid   LearnSQL.Class_t.ClassID%Type)
  RETURNS BOOLEAN AS 
$$
BEGIN 
  -- Check if days exists given the class id for the class.
  IF EXISTS (
              SELECT 1 
              FROM LearnSQL.Class_t
              WHERE Class_t.days = $1
              AND Class_t.classid = $2
            )
  THEN 
    RETURN TRUE;
  ELSE 
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;



-- This function defines whether the class has a start date associated with it.
CREATE OR REPLACE FUNCTION
  pg_temp.checkIfClassStartDateExists(startDate LearnSQL.Class_t.StartDate%Type,
                                      classid   LearnSQL.Class_t.ClassID%Type)
  RETURNS BOOLEAN AS 
$$ 
BEGIN 
  -- Check if the start date exists given the class id for the class.
  IF EXISTS (
              SELECT 1 
              FROM LearnSQL.Class_t
              WHERE Class_t.startDate = $1
              AND Class_t.classid = $2
            )
  THEN 
    RETURN TRUE;
  ELSE 
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;


-- This function creates test classes and drops test classes. After the classes
--  are successfully created, it then checks to see if the classes were dropped 
--  from the LearnSQL tables and if the class database was dropped. 
CREATE OR REPLACE FUNCTION
  pg_temp.createAndDropClassTest()
  RETURNS TEXT AS
$$
DECLARE 
  classID1 VARCHAR(63);
  classID2 VARCHAR(63);
  classID3 VARCHAR(63); 
BEGIN 
  -- Assign the classid to variables classID1, classID2, classID3 that is returned
  --  by the createClass function found in classMgmt.sql file.
  classID1 := LearnSQL.createClass('testadminuser', 'password', 'testuser1', 
                                   '123', 'class1', '1', 'time1', 'day1', 
                                   '2018-10-31', '2018-12-10');
  classID2 := LearnSQL.createClass('testadminuser', 'password', 'testuser2', 
                                   'pass2', 'class2', '2', 'time2', 'day2', 
                                   '2018-11-10', '2018-12-11');
  classID3 := LearnSQL.createClass('testadminuser', 'password', 'testuser3', 
                                   'pass3', 'class3', '3', 'time3', 'day3', 
                                   '2018-11-11', '2018-12-12');
  
  -- Checks if test classes have the necessary id's associated to each one of them. 
  IF NOT (pg_temp.checkIfClassIdExists(classID1)
    AND pg_temp.checkIfClassIdExists(classID2)
    AND pg_temp.checkIfClassIdExists(classID3))
  THEN
    RETURN 'Fail Code 1';
  END IF;
 
  -- Checks if the class name exists for each test class.
  IF NOT (pg_temp.checkIfClassNameExists('class1', classID1)
    AND pg_temp.checkIfClassNameExists('class2', classID2)
    AND pg_temp.checkIfClassNameExists('class3', classID3))
  THEN
    RETURN 'Fail Code 2';
  END IF;
  
  -- Checks if class section exists for each test class.
  IF NOT (pg_temp.checkIfClassSectionExists('1', classID1)
    AND pg_temp.checkIfClassSectionExists('2', classID2)
    AND pg_temp.checkIfClassSectionExists('3', classID3))
  THEN 
    RETURN 'Fail Code 3';
  END IF;

  -- Checks if a class time exists for each test class.
  IF NOT (pg_temp.checkIfClassTimeExists('time1', classID1)
    AND pg_temp.checkIfClassTimeExists('time2', classID2)
    AND pg_temp.checkIfClassTimeExists('time3', classID3))
  THEN 
    RETURN 'Fail Code 4';
  END IF;

  -- Checks if days exists for each test class.
  IF NOT (pg_temp.checkIfClassDaysExists('day1', classID1)
    AND pg_temp.checkIfClassDaysExists('day2', classID2)
    AND pg_temp.checkIfClassDaysExists('day3', classID3))
  THEN 
    RETURN 'Fail Code 5';
  END IF;

  -- Checks if a start date is given to each class.
  IF NOT (pg_temp.checkIfClassStartDateExists('2018-10-31', classID1)
    AND pg_temp.checkIfClassStartDateExists('2018-11-10', classID2)  
    AND pg_temp.checkIfClassStartDateExists('2018-11-11', classID3))
  THEN 
    RETURN 'Fail Code 6';
  END IF;
  
  -- Clean up test classes
  PERFORM LearnSQL.dropClass('testadminuser', 'password', 'testuser1', 'class1', 
                             '1', '2018-10-31');
  PERFORM LearnSQL.dropClass('testadminuser', 'password', 'testuser2', 'class2', 
                             '2', '2018-11-10');
  PERFORM LearnSQL.dropClass('testadminuser', 'password', 'testuser3', 'class3', 
                             '3', '2018-11-11');

  -- Check if the class id exists for any of the test classes and returns fail 
  --  code if it does exist.
  IF (pg_temp.checkIfClassIdExists(classID1)
    AND pg_temp.checkIfClassIdExists(classID2)
    AND pg_temp.checkIfClassIdExists(classID3)) 
  THEN
    RETURN 'Fail Code 7';
  END IF;

  RETURN 'Passed'; -- All test passed.
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION pg_temp.classMgmtTest() RETURNS VOID AS
$$
BEGIN
   RAISE INFO '%   createAndDropClassTest()',  pg_temp.createAndDropClassTest();
END;
$$  LANGUAGE plpgsql;



SELECT pg_temp.classMgmtTest();

ROLLBACK; -- Ignore all test data.



-- Revoke privileges to CREATEDB given to the temporary admin user.
REVOKE classdb_admin FROM testadminuser;
REVOKE CONNECT ON DATABASE LearnSQL FROM testadminuser;
DROP ROLE testadminuser; -- Drop the temporary admin user.



-- Drop all test users.
DROP USER testuser1;
DROP USER testuser2;
DROP USER testuser3;



-- Delete test users from the LearnSQL userdata_t table.
DELETE FROM LearnSQL.Userdata_t 
WHERE Username IN ('testuser1','testuser2', 'testuser3');