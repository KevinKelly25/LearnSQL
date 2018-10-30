-- classMgmt.sql - LearnSQL

-- Michael Torres
-- Web Applications and Databases for Education (WADE)

-- This file creates the functions involved with class management in the LearnSQL
--  database. This file should be run after createLearnSQLTables.sql



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



-- Suppress NOTICES for this script only, this will not apply to functions
--  defined within. This hides unimportant, but possibly confusing messages.
SET LOCAL client_min_messages TO WARNING;



-- Define function to create a class. 
-- This function will create a class within the database and learnsql tables. 
-- If any errors are encounterd an exception will be raised and the function
--  will stop execution.
CREATE OR REPLACE FUNCTION 
  LearnSQL.createClass(
                        dbUserName            VARCHAR(60),
                        dbPassword            VARCHAR(64),
                        teacherUserName       LearnSQL.UserData_t.UserName%Type,
                        classPassword         LearnSQL.Class_t.Password%Type,
                        className             LearnSQL.Class_t.ClassName%Type,
                        section               LearnSQL.Class_t.Section%Type,
                        times                 LearnSQL.Class_t.Times%Type,
                        days                  LearnSQL.Class_t.Days%Type,
                        startDate             LearnSQL.Class_t.StartDate%Type
                          DEFAULT CURRENT_DATE,
                        endDate               LearnSQL.Class_t.EndDate%Type DEFAULT NULL)
  RETURNS VARCHAR AS
$$
DECLARE
  classid VARCHAR(63);
  encryptedPassword VARCHAR(60); -- hashed password to be stored in UserData_t
BEGIN
  classid := $5 || '_' || gen_random_uuid();
  -- Any instances of the character '-' is deleted from the classid or else this
  --  will cause an error in dblink. 
  classid := REPLACE (classid, '-', '');

  -- Check if user creating class is a teacher
  IF NOT EXISTS (
                  SELECT 1 
                  FROM LearnSQL.UserData_t
                  WHERE UserData_t.userName = $3
                  AND UserData_t.isTeacher = TRUE 
                ) 
  THEN 
    RAISE EXCEPTION 'Class Creation Not Possible For Current User!';
  END IF;

  -- Check if class name and class section for user logged in already exists
  IF EXISTS (
              SELECT 1 
              FROM LearnSQL.Class_t INNER JOIN LearnSQL.Attends
              ON Attends.classID = Class_t.classID
              WHERE Attends.userName = $3
              AND Class_t.className = $5
              AND Class_t.section = $6
            ) 
  THEN 
    RAISE EXCEPTION 'Section And Class Name Already Exists!';
  END IF;

  -- Check if the class database already exists
  IF EXISTS (
              SELECT 1
              FROM pg_database 
              WHERE datname = classid
            )
  THEN 
    RAISE EXCEPTION 'This Class Database Already Exists!';
  END IF;

  -- Create "hashed" password using blowfish cipher
  encryptedPassword = crypt($2, gen_salt('bf'));

  --insert into class all class information
  INSERT INTO LearnSQL.Class_t VALUES (LOWER(classID), $5, $6, $7, $8, $9, $10, encryptedPassword);

  --insert into attends table
  INSERT INTO learnsql.Attends VALUES (LOWER(classID), $3, TRUE);

  -- Cross database link query that creates the database classid with the owner as classdb_admin
  PERFORM * 
  FROM LearnSQL.dblink ('user=' || $1 || ' dbname=learnsql password='|| $2,
               'CREATE DATABASE ' || LOWER(classID) || ' WITH TEMPLATE classdb_template OWNER classdb_admin')
    AS throwAway(blank VARCHAR(30));--needed for dblink but unused
  
  -- Cross database link query that gives access privileges to the database classid
  PERFORM *
  FROM LearnSQL.dblink ('user=' || $1 || ' dbname= ' || LOWER(classID) || ' password=' || $2,
               'SELECT reAddUserAccess()')
    AS throwAway(blank VARCHAR(30));--needed for dblink but unused

  RETURN classID;
END;
$$ LANGUAGE plpgsql;



-- getClassID function returns theClassID to be used in dropClass function so that 
--  the class id does not have to be supplied as a parameter.
CREATE OR REPLACE FUNCTION 
  LearnSQL.getClassID (
                       username     LearnSQL.Attends.UserName%Type,
                       className    LearnSQL.Class_t.ClassName%Type,
                       classSection LearnSQL.Class_t.Section%Type,
                       startDate    LearnSQL.Class_t.StartDate%Type)
  RETURNS VARCHAR AS 
$$ 
DECLARE 
  theClassId LearnSQL.Class_t.classID%Type;
BEGIN 

  -- Returns the classid and assigns it to theClassID  
  SELECT LearnSQL.Class_t.classID
  INTO theClassId
  FROM LearnSQL.Class_t INNER JOIN LearnSQL.Attends
  ON Attends.classID = Class_t.classID
  WHERE Attends.userName = $1
  AND Class_t.className = $2
  AND Class_t.section = $3
  AND Class_t.startDate = $4;

  RETURN LOWER(theClassId);
END;
$$ LANGUAGE plpgsql;
                       


CREATE OR REPLACE FUNCTION
  LearnSQL.dropClass(
                     dbUserName                 VARCHAR(63),
                     dbPassword                 VARCHAR(64),
                     teacherUserName            LearnSQL.UserData_t.userName%Type,
                     className                  LearnSQL.Class_t.ClassName%Type,
                     classSection               LearnSQL.Class_t.Section%Type,
                     startDate                  LearnSQL.Class_t.StartDate%Type)
  RETURNS VOID AS
$$
DECLARE 
  theClassID VARCHAR := learnSQL.getClassID($3, $4, $5, $6);
BEGIN 
  
  -- Check if classname exists in LearnSQL tables
  IF NOT EXISTS (
                  SELECT 1
                  FROM LearnSQL.Class_t
                  WHERE Class_t.ClassName = $4
                )
  THEN 
    RAISE EXCEPTION 'Class Does Not Exists In Class_t Table';
  END IF;

  -- Check if the class exists in the database
  IF NOT EXISTS (
                  SELECT 1 
                  FROM pg_database
                  WHERE datname = theClassID
                )
  THEN 
    RAISE EXCEPTION 'Class Not Found In Database %', theClassID;
  END IF;

  -- Check if class name and class section for user logged in already exists
  IF NOT EXISTS (
                  SELECT 1 
                  FROM LearnSQL.Class_t INNER JOIN LearnSQL.Attends
                  ON Attends.classID = Class_t.classID
                  WHERE Attends.userName = $3
                  AND Class_t.className = $4
                  AND Class_t.section = $5
                  AND Class_t.startDate = $6
                ) 
  THEN 
    RAISE EXCEPTION 'Drop Failed - User Currently Not Attending This Class!';
  END IF;

  -- Check if user that is dropping the class is a teacher
  IF NOT EXISTS (
                  SELECT 1  
                  FROM LearnSQL.UserData_t 
                  WHERE UserData_t.userName = $3
                  AND UserData_t.isTeacher = true
                )
  THEN 
    RAISE EXCEPTION 'Only A Teacher Is Allowed To Drop A Class';
  END IF;

  -- Cross database link query to drop class from the database
  PERFORM *
  FROM LearnSQL.dblink('user='|| $1 ||' dbname=learnsql  password='|| $2, 
              'DROP DATABASE '|| theClassID)
  AS throwAway(blank VARCHAR(30));--needed for dblink but unused

  -- Delete classes from the learnSQL Attends table
  DELETE FROM LearnSQL.Attends
  WHERE Attends.classID = theClassID;
  
  -- Delete classes from the LearnSQL Class_t table
  DELETE From LearnSQL.Class_t
  WHERE Class_t.classID = theClassID;
END;
$$ LANGUAGE plpgsql;

COMMIT;