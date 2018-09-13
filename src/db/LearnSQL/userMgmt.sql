-- userMgmt.sql - LearnSQL

-- Kevin Kelly
-- Web Applications and Databases for Education (WADE)

-- This file creates the functions involved with user management in the LearnSQL
--  database.This file should be run after createLearnSQLTables.sql

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



-- Define a table of user information for this DB
--  a "Username" is a unique id that represents a human user
--  a "Password" represents the hashed and salted password of a user
--  the "Email" field characters are check to make sure they follow the scheme
--   of a valid email
--  a "token" represents a hashed token used for password reset and email validation
--  "isVerified" represents whether the user verified their email.
--  "forgotPassword" represents if the forgotPassword feature was used.
CREATE TABLE IF NOT EXISTS UserData_t (
  Username                VARCHAR(256) NOT NULL PRIMARY KEY,
  FullName                VARCHAR(256) NOT NULL,
  Password                VARCHAR(60) NOT NULL,
  Email                   VARCHAR(319) NOT NULL CHECK(TRIM(Email) like '_%@_%._%'),
  Token                   VARCHAR(60) NOT NULL,
  DateJoined              DATE DEFAULT CURRENT_DATE,
  isTeacher               BOOLEAN DEFAULT FALSE,
  isAdmin                 BOOLEAN DEFAULT FALSE,
  isVerified              BOOLEAN DEFAULT FALSE,
  ForgotPassword          BOOLEAN DEFAULT FALSE
);



-- Define a unique index on the trimmer and lowercase values of the email field
CREATE UNIQUE INDEX idx_Unique_Email ON UserData_t(LOWER(TRIM(Email)));



--Define function to register a user.
CREATE OR REPLACE FUNCTION
  LearnSQL.createUser(UserName VARCHAR(256),
                      FullName VARCHAR(256),
                      Password VARCHAR(60),
                      Email    VARCHAR(319))
   RETURNS VOID AS
$$
BEGIN
  --Check if username exists
  IF EXISTS (SELECT *
             FROM UserData_t
             WHERE UserData_t.UserName = $1
      ) THEN
    RAISE EXCEPTION 'Username Already Exists';
  END IF;


  --Check if Email exists
  IF EXISTS (SELECT *
             FROM UserData_t
             WHERE UserData_t.Email = $4
      ) THEN
    RAISE EXCEPTION 'Email Already Exists';
  END IF;

  --Add user information to the LearnSQL UserData table
  INSERT INTO UserData_t VALUES ($1,$2,$3,$4, (SELECT MD5(random()::text)));

  --create database user
  EXECUTE FORMAT('CREATE USER %s WITH ENCRYPTED PASSWORD %L',$1, $3)

END;
$$ LANGUAGE plpgsql;




COMMIT;