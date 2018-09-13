-- initializeDB.sql - LearnSQL

-- Kevin Kelly, Michael Torres
-- Web Applications and Databases for Education (WADE)

-- This script runs the database setup functions

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

--Create a schema to hold app's admin info and assign privileges on that schema
CREATE SCHEMA IF NOT EXISTS LearnSQL AUTHORIZATION learnsql;



--Remove access to the database from anyone other then superusers
DO
$$
DECLARE
   currentDB VARCHAR(128);
BEGIN
   currentDB := current_database();

   --Disallow DB connection to all users
   -- Postgres grants CONNECT to all by default
   EXECUTE format('REVOKE CONNECT ON DATABASE %I FROM PUBLIC', currentDB);

END
$$;



--TODO: move Class Tables to ClassMgmt script
-- Define a table of classes for this DB
--  a "ClassID" is a unique id that represents a classname plus a random ID
--  a "ClassName" is the classID without the random ID
--  the "Password" field will be used for students to create their student
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
  Username                VARCHAR(256) NOT NULL REFERENCES UserData_t,
  isTeacher               BOOLEAN DEFAULT FALSE,
  PRIMARY KEY (ClassID, Username)
);



-- Define a view to return Class data
--  This view has all attributes of Class_t with an added derived attribute
--  "studentCount"
--  "studentCount" represents the number of students in a class.
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
-- "isstudent"
-- "isstudent" represents a student taking a class.
CREATE OR REPLACE VIEW UserData AS 
SELECT Username, Fullname, Password, Email, Token, DateJoined, isTeacher,
       isAdmin, isVerified, ForgotPassword,
EXISTS 
  (
    SELECT *
    FROM Attends 
    WHERE Attends.Username = UserData_t.Username AND Attends.isTeacher = FALSE
  ) AS isstudent
FROM UserData_t;

COMMIT;