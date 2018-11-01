-- testClassMgmt.sql - LearnSQL

-- Michael Torres
-- Web Applications and Databases for Education (WADE)

-- This file tests the functions involved with class management in the LearnSQL
--  database

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



-- check if the class exists in the database and in the learnsql tables
CREATE OR REPLACE FUNCTION
  pg_temp.checkIfClassIdExists(classid LearnSQL.Class_t.ClassID%Type)
  RETURNS BOOLEAN AS 
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



-- Check if the class name exists
CREATE OR REPLACE FUNCTION
  pg_temp.checkIfClassNameExists(className LearnSQL.Class_t.ClassName%Type,
                                 classid   LearnSQL.Class_t.ClassID%Type)
  RETURNS BOOLEAN AS 
$$
BEGIN
  -- Check if the class name exists given the class id
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



-- This function defines whether the class has a corresponding section
CREATE OR REPLACE FUNCTION 
  pg_temp.checkIfClassSectionExists(classSection LearnSQL.Class_t.Section%Type,
                                    classid      LearnSQL.Class_t.ClassID%Type)
  RETURNS BOOLEAN AS 
$$ 
BEGIN 
  -- Check if section exists given the class id for the class
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



-- This function defines whether the class has a time to it
CREATE OR REPLACE FUNCTION
  pg_temp.checkIfClassTimeExists(classTimes LearnSQL.Class_t.Times%Type,
                                 classid    LearnSQL.Class_t.ClassID%Type)
  RETURNS BOOLEAN AS 
$$ 
BEGIN 
  -- Check if a time exists given the class id for the class
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



-- This function defines whether the class has the days of when it runs
CREATE OR REPLACE FUNCTION
  pg_temp.checkIfClassDaysExists(classDays LearnSQL.Class_t.Days%Type,
                                 classid   LearnSQL.Class_t.ClassID%Type)
  RETURNS BOOLEAN AS 
$$
BEGIN 
  -- Check if days exists given the class id for the class
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



-- This function defines whether the class has a start date associated with it
CREATE OR REPLACE FUNCTION
  pg_temp.checkIfClassStartDateExists(startDate LearnSQL.Class_t.StartDate%Type,
                                      classid   LearnSQL.Class_t.ClassID%Type)
  RETURNS BOOLEAN AS 
$$ 
BEGIN 
  -- Check if the start date exists given the class id for the class
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



CREATE OR REPLACE FUNCTION
  pg_temp.createAndDropClassTest()
  RETURNS TEXT AS
$$
DECLARE 
  classID1 VARCHAR(63);
  classID2 VARCHAR(63);
  classID3 VARCHAR(63); 
BEGIN 

  classID1 := LearnSQL.createClass('testadminuser', 'password', 'testuser1', '123', 'class1', '1', 'time1', 'day1', '2018-10-31', '2018-12-10');
  classID2 := LearnSQL.createClass('testadminuser', 'password', 'testuser2', 'pass2', 'class2', '2', 'time2', 'day2', '2018-11-10', '2018-12-11');
  classID3 := LearnSQL.createClass('testadminuser', 'password', 'testuser3', 'pass3', 'class3', '3', 'time3', 'day3', '2018-11-11', '2018-12-12');
  
  PERFORM pg_temp.checkIfClassIdExists(classID1);
  PERFORM pg_temp.checkIfClassIdExists(classID2);
  PERFORM pg_temp.checkIfClassIdExists(classID3);

  PERFORM pg_temp.checkIfClassNameExists('class1', classID1);
  PERFORM pg_temp.checkIfClassNameExists('class2', classID2);
  PERFORM pg_temp.checkIfClassNameExists('class3', classID3);

  PERFORM pg_temp.checkIfClassSectionExists('1', classID1);
  PERFORM pg_temp.checkIfClassSectionExists('2', classID2);
  PERFORM pg_temp.checkIfClassSectionExists('3', classID3);

  PERFORM pg_temp.checkIfClassTimeExists('time1', classID1);
  PERFORM pg_temp.checkIfClassTimeExists('time2', classID2);
  PERFORM pg_temp.checkIfClassTimeExists('time3', classID3);

  PERFORM pg_temp.checkIfClassDaysExists('day1', classID1);
  PERFORM pg_temp.checkIfClassDaysExists('day2', classID2);
  PERFORM pg_temp.checkIfClassDaysExists('day3', classID3);

  PERFORM pg_temp.checkIfClassStartDateExists('2018-10-31', classID1); 
  PERFORM pg_temp.checkIfClassStartDateExists('2018-11-10', classID2);  
  PERFORM pg_temp.checkIfClassStartDateExists('2018-11-11', classID3);

  -- Clean up test classes
  PERFORM LearnSQL.dropClass('testadminuser', 'password', 'testuser1', 'class1', '1', '2018-10-31');
  PERFORM LearnSQL.dropClass('testadminuser', 'password', 'testuser2', 'class2', '2', '2018-11-10');
  PERFORM LearnSQL.dropClass('testadminuser', 'password', 'testuser3', 'class3', '3', '2018-11-11');

  -- Check if the 
  IF (pg_temp.checkIfClassIdExists(classID1)
    AND pg_temp.checkIfClassIdExists(classID2)
    AND pg_temp.checkIfClassIdExists(classID3)) 
  THEN
    RETURN 'Fail Code 1';
  END IF;

  RETURN 'passed';
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION pg_temp.classMgmtTest() RETURNS VOID AS
$$
BEGIN
   RAISE INFO '%   createAndDropClassTest()',  pg_temp.createAndDropClassTest();
END;
$$  LANGUAGE plpgsql;



SELECT pg_temp.classMgmtTest();



ROLLBACK;



REVOKE classdb_admin FROM testadminuser;
REVOKE CONNECT ON DATABASE LearnSQL FROM testadminuser;
DROP ROLE testadminuser;