-- initializeDB.sql - LearnSQL

-- Kevin Kelly, Michael Torres
-- Web Applications and Databases for Education (WADE)

-- This script runs the database setup functions

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

-- Create a schema to hold app's admin info and assign privileges on that schema
CREATE SCHEMA IF NOT EXISTS LearnSQL AUTHORIZATION learnsql;



-- Remove access to the database from anyone other then superusers
DO
$$
DECLARE
   currentDB VARCHAR(128);
BEGIN
   currentDB := current_database();

   -- Disallow DB connection to all users
   --  Postgres grants CONNECT to all by default
   EXECUTE format('REVOKE CONNECT ON DATABASE %I FROM PUBLIC', currentDB);

END
$$;


-- Define a table of user information for this DB
--  A "Username" is a unique id that represents a human user
--  A "Password" represents the hashed and salted password of a user
--  The "Email" field characters are check to make sure they follow the scheme
--   of a valid email
--  A "token" represents a hashed token used for password reset and email validation
--  "isVerified" represents whether the user verified their email
--  "forgotPassword" represents if the forgotPassword feature was used
CREATE TABLE IF NOT EXISTS LearnSQL.UserData_t (
  Username                VARCHAR(256) NOT NULL
    CHECK(TRIM(Username) <> ''), 
  FullName                VARCHAR(256) NOT NULL
    CHECK(TRIM(FullName) <> ''),
  Password                VARCHAR(60) NOT NULL
    CHECK(LENGTH(Password) = 60),
  Email                   VARCHAR(319) NOT NULL 
    CHECK(TRIM(Email) like '_%@_%._%'),
  Token                   VARCHAR(60) NOT NULL,
    CHECK(LENGTH(Token) = 60),
  isTeacher               BOOLEAN DEFAULT FALSE,
  isAdmin                 BOOLEAN DEFAULT FALSE,
  DateJoined              DATE DEFAULT CURRENT_DATE,
  isVerified              BOOLEAN DEFAULT FALSE,
  ForgotPassword          BOOLEAN DEFAULT FALSE,
  TokenTimestamp          DATE DEFAULT CURRENT_TIMESTAMP
);

-- Define a unique index on the trimmed and lowercase values of the Username field
-- so that it matches the username that will be stored in the server
CREATE UNIQUE INDEX IF NOT EXISTS idx_Unique_Username 
  ON LearnSQL.UserData_t(LOWER(TRIM(Username)));


-- Define a unique index on the trimmed and lowercase values of the email field
CREATE UNIQUE INDEX IF NOT EXISTS idx_Unique_Email 
  ON LearnSQL.UserData_t(LOWER(TRIM(Email)));



-- Define a table of classes for this DB
--  a "ClassID" is a unique id that represents a classname plus a random ID
--  a "ClassName" is the classID without the random ID
--  The "Password" field will be used for students to create their student
--   account in the classdb database
CREATE TABLE IF NOT EXISTS Class_t (
  ClassID                 VARCHAR(256) NOT NULL PRIMARY KEY,
  ClassName               VARCHAR(236) NOT NULL,
  Section                 VARCHAR(256) NOT NULL,
  Times                   VARCHAR(256) NOT NULL,
  Days                    VARCHAR(256) NOT NULL,
  StartDate               VARCHAR(256) NOT NULL,
  EndDate                 VARCHAR(256) NOT NULL,
  Password                VARCHAR(60)  NOT NULL
);



-- Define a table that represents the relation between UserData and Class
--  a "Username" is a unique id that represents a human user from UserData table
--  a "ClassID" is a unique id that represents a class from Class table
--  "isTeacher" defines whether user is a teacher for that specific class
CREATE TABLE IF NOT EXISTS Attends (
  ClassID                 VARCHAR(256) NOT NULL REFERENCES Class_t,
  Username                VARCHAR(256) NOT NULL,
  isTeacher               BOOLEAN DEFAULT FALSE,
  PRIMARY KEY (ClassID, Username)
);



-- Define a view to return Class data
--  This view has all attributes of Class_t with an added derived attribute
--   "studentCount"
--  A "studentCount" represents the number of students in a class
CREATE OR REPLACE VIEW Class AS
SELECT ClassID, ClassName, Section, Times, Days, StartDate, EndDate, Password,
  (
    SELECT COUNT(*)
    FROM Attends
    WHERE Attends.ClassID = Class_t.ClassID AND isTeacher = FALSE
  ) AS studentCount
FROM Class_t;



-- Define a view to return UserData data
-- This view has all attributes of UserData_t with an added derived attribute
--  "isstudent"
-- The attribute "isstudent" represents if a student is taking a class
CREATE OR REPLACE VIEW LearnSQL.UserData AS 
SELECT Username, Fullname, Password, Email, Token, DateJoined, isTeacher,
       isAdmin, isVerified, ForgotPassword, TokenTimestamp,
EXISTS 
  (
    SELECT *
    FROM Attends 
    WHERE Attends.Username = UserData_t.Username AND Attends.isTeacher = FALSE
  ) AS isstudent
FROM LearnSQL.UserData_t;

COMMIT;