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
  END
$$;



-- Suppress NOTICEs for this script only, this will not apply to functions
--  defined within. This hides unimportant, but possibly confusing messages
SET LOCAL client_min_messages TO WARNING;

-- Define function to create a class. 
-- TODO: create more comments
CREATE OR REPLACE FUNCTION 
  LearnSQL.createClass(
                        dbName         VARCHAR(60),
                        dbPassword     VARCHAR(64),
                        userName       LearnSQL.UserData_t.UserName%Type,
                        classPassword  LearnSQL.Class_t.Password%Type,
                        classID        LearnSQL.Class_t.ClassID%Type,
                        className      LearnSQL.Class_t.ClassName%Type,
                        section        LearnSQL.Class_t.Section%Type,
                        times          LearnSQL.Class_t.Times%Type,
                        days           LearnSQL.Class_t.Days%Type,
                        startDate      LearnSQL.Class_t.StartDate%Type
                          DEFAULT CURRENT_DATE,
                        endDate        LearnSQL.Class_t.EndDate%Type DEFAULT NULL
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
                  WHERE UserData_t.userName = $3
                  AND UserData_t.isTeacher = TRUE 
                ) 
  THEN 
    RAISE EXCEPTION 'Class Creation Not Possible For Current User';
  END IF;

  -- Check if class name and class section for user logged in already exists
  IF EXISTS (
              SELECT 1 
              FROM LearnSQL.Class_t INNER JOIN LearnSQL.Attends
              ON Attends.classID = Class_t.classID
              WHERE Attends.userName = $3
              AND Class_t.className = $6
              AND Class_t.section = $7
            ) 
  THEN 
    RAISE EXCEPTION 'Section And Class Name Already Exists!';
  END IF;

  -- Check if the class database already exists
  IF EXISTS (
              SELECT 1
              FROM pg_database 
              WHERE datname = $3
            )
  THEN 
    RAISE EXCEPTION 'This Class Database Already Exists!';
  END IF;

  -- Create "hashed" password using blowfish cipher
  encryptedPassword = crypt($2, gen_salt('bf'));

  --insert into class all class information
  INSERT INTO LearnSQL.Class_t VALUES ($5, $6, $7, $8, $9, $10, $11, encryptedPassword);

  --insert into attends table
  INSERT INTO learnsql.Attends VALUES ($5, $3, TRUE);

  -- dblink 
  SELECT *
  FROM dblink('user='|| $1 ||' dbname=learnsql  password='|| $2, 
              'CREATE DATABASE '|| $5)
  AS throwAway(blank VARCHAR(30));--needed for dblink but unused

END
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION
  LearnSQL.dropClass(className           LearnSQL.Class_t.ClassName%Type
                     databaseClassname   VARCHAR DEFAULT NULL,
                     databasePassword    VARCHAR DEFAULT NULL)
  RETURNS VOID AS
$$
DECLARE 
  rec RECORD;
BEGIN 
  -- Check if classname exists in LearnSQL tables
  IF NOT EXISTS (
                  SELECT 1
                  FROM LearnSQL.Class_t
                  WHERE Class_t.ClassName = $1;
                )
  THEN 
    RAISE EXCEPTION 'Class does not exist in tables';
  END IF;

  -- Check if class exists in database
  IF ($2 IS NOT NULL AND $3 IS NOT NULL) THEN 
    IF NOT EXISTS (
                    SELECT 1 
                    FROM pg_catalog.pg_roles
                    WHERE rolname = $1 
                  )
    THEN 
      RAISE EXCEPTION 'Class does not exists in database';
  END IF;