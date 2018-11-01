-- testClassMgmt.sql - LearnSQL

-- Michael Torres
-- Web Applications and Databases for Education (WADE)

-- This file tests the functions involved with class management in the LearnSQL
--  database.



-- Create a user with privilege for CREATE DB which will be used for testing.
CREATE USER testadminuser WITH PASSWORD 'password' CREATEDB;
GRANT CONNECT ON DATABASE learnSQL TO testadminuser;
GRANT classdb_admin TO testadminuser;



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



-- This function checks if the class exists in the database and in the learnsql 
--  tables.
CREATE OR REPLACE FUNCTION
  pg_temp.checkIfClassIdExists(classid LearnSQL.Class_t.ClassID%Type)
  RETURNS BOOLEAN AS 
$$
BEGIN 
  -- Check if the class exists in the postgres database.
  IF NOT EXISTS (
                  SELECT 1 
                  FROM pg_database
                  WHERE datname = $1
                )
  THEN
    RETURN FALSE;
  END IF;

  -- Check if the class exists in the learnSQL Attends table.
  IF NOT EXISTS (
                  SELECT 1 
                  FROM LearnSQL.Attends
                  WHERE Attends.classid = $1
                )
  THEN 
    RETURN FALSE;
  END IF;

  -- Check if the class exists in the learnSQL Class_t table.
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



-- This fucntion checks if the class name exists.
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
--  are successfully created, it then checks to see if the classes were drop from
--  the LearnSQL tables and the database classes as well. 
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
  classID1 := LearnSQL.createClass('testadminuser', 'password', 'testuser1', '123', 'class1', '1', 'time1', 'day1', '2018-10-31', '2018-12-10');
  classID2 := LearnSQL.createClass('testadminuser', 'password', 'testuser2', 'pass2', 'class2', '2', 'time2', 'day2', '2018-11-10', '2018-12-11');
  classID3 := LearnSQL.createClass('testadminuser', 'password', 'testuser3', 'pass3', 'class3', '3', 'time3', 'day3', '2018-11-11', '2018-12-12');
  
  -- Checks if test classes have the necessary id's associated to each one of them.
  PERFORM pg_temp.checkIfClassIdExists(classID1);
  PERFORM pg_temp.checkIfClassIdExists(classID2);
  PERFORM pg_temp.checkIfClassIdExists(classID3);
 
  -- Checks if the class name exists for each test class.
  PERFORM pg_temp.checkIfClassNameExists('class1', classID1);
  PERFORM pg_temp.checkIfClassNameExists('class2', classID2);
  PERFORM pg_temp.checkIfClassNameExists('class3', classID3);
  
  -- Checks if class section exists for each test class.
  PERFORM pg_temp.checkIfClassSectionExists('1', classID1);
  PERFORM pg_temp.checkIfClassSectionExists('2', classID2);
  PERFORM pg_temp.checkIfClassSectionExists('3', classID3);

  -- Checks if a class time exists for each test class.
  PERFORM pg_temp.checkIfClassTimeExists('time1', classID1);
  PERFORM pg_temp.checkIfClassTimeExists('time2', classID2);
  PERFORM pg_temp.checkIfClassTimeExists('time3', classID3);

  -- Checks if days exists for each test class.
  PERFORM pg_temp.checkIfClassDaysExists('day1', classID1);
  PERFORM pg_temp.checkIfClassDaysExists('day2', classID2);
  PERFORM pg_temp.checkIfClassDaysExists('day3', classID3);

  -- Checks if a start date is given to each class.
  PERFORM pg_temp.checkIfClassStartDateExists('2018-10-31', classID1); 
  PERFORM pg_temp.checkIfClassStartDateExists('2018-11-10', classID2);  
  PERFORM pg_temp.checkIfClassStartDateExists('2018-11-11', classID3);

  -- Clean up test classes
  PERFORM LearnSQL.dropClass('testadminuser', 'password', 'testuser1', 'class1', '1', '2018-10-31');
  PERFORM LearnSQL.dropClass('testadminuser', 'password', 'testuser2', 'class2', '2', '2018-11-10');
  PERFORM LearnSQL.dropClass('testadminuser', 'password', 'testuser3', 'class3', '3', '2018-11-11');

  -- Check if the class id exists for any of the test classes and returns fail 
  --  code if it does exist.
  IF (pg_temp.checkIfClassIdExists(classID1)
    AND pg_temp.checkIfClassIdExists(classID2)
    AND pg_temp.checkIfClassIdExists(classID3)) 
  THEN
    RETURN 'Fail Code 1';
  END IF;

  RETURN 'passed'; -- All test passed.
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION pg_temp.classMgmtTest() RETURNS VOID AS
$$
BEGIN
   RAISE INFO '%   createAndDropClassTest()',  pg_temp.createAndDropClassTest();
END;
$$  LANGUAGE plpgsql;



SELECT pg_temp.classMgmtTest();



ROLLBACK; -- Ignore all test data



-- Drop the test user.
REVOKE classdb_admin FROM testadminuser;
REVOKE CONNECT ON DATABASE LearnSQL FROM testadminuser;
DROP ROLE testadminuser;