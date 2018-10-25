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
    IF NOT EXISTS (SELECT * FROM pg_catalog.pg_roles
                   WHERE rolname = CURRENT_USER AND rolsuper = TRUE
                  ) 
        THEN
        RAISE EXCEPTION 'Insufficient privileges: script must be run as a user '
                        'with superuser privileges';
    END IF;
  END
$$;



-- Suppress NOTICEs for this script only, this will not apply to functions
--  defined within. This hides unimportant, but possibly confusing messages
SET LOCAL client_min_messages TO WARNING;

-- Define function to create a class. 
-- TODO: create more comments
CREATE OR REPLACE FUNCTION 
  LearnSQL.createClass(
                        userName  LearnSQL.UserData_t.UserName%Type,
                        password  LearnSQL.Class_t.Password%Type,
                        classID   LearnSQL.Class_t.ClassID%Type,
                        className LearnSQL.Class_t.ClassName%Type,
                        section   LearnSQL.Class_t.Section%Type,
                        times     LearnSQL.Class_t.Times%Type,
                        days      LearnSQL.Class_t.Days%Type,
                        startDate LearnSQL.Class_t.StartDate%Type,
                        endDate   LearnSQL.Class_t.EndDate%Type 
                      )
  RETURNS VOID AS
$$
DECLARE
  encryptedPassword VARCHAR(60); -- hashed password to be stored in UserData_t
BEGIN
  -- Check if user creating class is a teacher
  IF NOT EXISTS (
                  SELECT 1 
                  FROM LearnSQL.UserData_t
                  WHERE UserData_t.userName = $1
                  AND UserData_t.isTeacher = TRUE 
                ) 
  THEN 
    RAISE EXCEPTION 'Class Creation Not Possible For Current User';
  END IF;

  -- Check if classID already exists
  IF EXISTS (
              SELECT * 
              FROM LearnSQL.Class_t
              WHERE Class_t.ClassID = $3
            ) 
  THEN 
    RAISE EXCEPTION 'ClassID Already Exists';
  END IF;

  -- Check if class name and class section for user logged in already exists
  IF EXISTS (
              SELECT 1 
              FROM LearnSQL.Class_t INNER JOIN LearnSQL.Attends
              ON Attends.classID = Class_t.classID
              WHERE Attends.userName = $1
              AND Class_t.className = $4
              AND Class_t.section = $5
            ) 
  THEN 
    RAISE EXCEPTION 'Section And Class Name Already Exists!';
  END IF;

  -- Create "hashed" password using blowfish cipher
  encryptedPassword = crypt($2, gen_salt('bf'));

  --insert into class all class information
  INSERT INTO LearnSQL.Class_t VALUES ($3, $4, $5, $6, $7, $8, $9, encryptedPassword);

  -- Create database class
  EXECUTE FORMAT('CREATE CLASS %s WITH ENCRYPTED PASSWORD %L', LOWER($4), $2);

END
$$ LANGUAGE plpgsql;