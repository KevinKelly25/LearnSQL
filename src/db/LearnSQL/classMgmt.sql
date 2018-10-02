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
                  ) THEN
        RAISE EXCEPTION 'Insufficient privileges: script must be run as a user '
                        'with superuser privileges';
    END IF;
  END
$$;



--Enable the pgcrypto extension for PostgreSQL for hashing and generating salts
CREATE EXTENSION IF NOT EXISTS pgcrypto;



-- Define function to create a class. TODO: add some more comments
CREATE OR REPLACE FUNCTION 
  LearnSQL.createClass(
                       classID LearnSQL.Class_t.ClassID%Type,
                       className LearnSQL.Class_t.ClassName%Type,
                       section LearnSQL.Class_t.Section%Type,
                       times LearnSQL.Class_t.Times%Type,
                       days LearnSQL.Class_t.Days%Type,
                       startDate LearnSQL.Class_t.StartDate%Type,
                       endDate LearnSQL.Class_t.EndDate%Type,
                       password LearnSQL.Class_t.Password%Type,
                       userName LearnSQL.UserData_t.UserName%Type
                      )
  RETURNS VOID AS
$$
  DECLARE
    ecryptedPassword VARCHAR(60); -- hashed password to be stored in Class_t
  BEGIN
    -- Check if user creating class is a teacher
    IF NOT EXISTS (
                  SELECT 1 
                  FROM UserData_t
                  WHERE UserData_t.userName = $9
                  AND UserData_t.isTeacher = TRUE 
                  ) THEN 
      RAISE EXCEPTION 'Class Creation Not Possible For Current User'
    END IF;

    -- Check if classID already exists
    IF EXISTS (
              SELECT * 
              FROM Class_t
              WHERE Class_t.ClassID = $1
              ) THEN 
      RAISE EXCEPTION 'ClassID Already Exists';
    END IF;

    -- Check if class section already exists



    -- Create "hashed" password using blowfish cipher.
    encryptedPassword = crypt($8, gen_salt('bf'));

    -- Add class information to the LearnSQL Class table
    INSERT INTO Class_t VALUES ($1, $2, $3, $4, $5, $6, $7, 
                                encryptedPassword);

    -- Create database class
    EXECUTE FORMAT('CREATE CLASS %s WITH ENCRYPTED PASSWORD %L', $1, $8);
  END;
$$ LANGUGAGE plpgsql;

--Define function to delete a class.
CREATE OR REPLACE FUNCTION 
  LearnSQL.dropClass(class LearnSQL.Class_t.ClassID%Type,
                     databasePassword VARCHAR DEFAULT NULL)
  RETURN VOID AS 
$$ 
  BEGIN 
    -- Check if classid exists in LearnSQL tables
    IF NOT EXISTS (
                   SELECT *
                   FROM LearnSQL.Class_t
                   WHERE Class_t.ClassID = $1
                  ) THEN 
      RAISE EXCEPTION 'Class does not exists in tables';
    END IF;

    --Check if class exists in database
    IF $2 NOT NULL THEN 
      IF NOT EXISTS (
                     SELECT *
                     FROM pg_catalog.pg_roles
                     WHERE rolname = $1
                    ) THEN 
        RAISE EXCEPTION 'Class does not exists in database';
      END IF;

      -- drop class

    END IF;