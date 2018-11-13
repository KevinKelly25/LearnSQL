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
   EXECUTE format('REVOKE CONNECT ON DATABASE %I FROM public', currentDB);

   -- Only allow connect from learnsql role
   EXECUTE format('GRANT CONNECT ON DATABASE %I TO learnsql', currentDB);
END
$$;



-- Define a table of user information for this DB
--  A "Username" is a unique id that represents a user. Usernames are used as 
--   the primary key.
--  A "Password" represents the hashed and salted password of a user
--  The "Email" field characters are check to make sure they follow the scheme
--   of a valid email
--  A "token" represents a hashed token used for password reset and email validation
--  "isVerified" represents whether the user verified their email
--  "forgotPassword" represents if the forgotPassword feature was used
CREATE TABLE IF NOT EXISTS LearnSQL.UserData_t (
  Username                VARCHAR(63) NOT NULL
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
  DateJoined              DATE DEFAULT CURRENT_DATE
    CHECK (DateJoined > '2018-01-01'),
  isVerified              BOOLEAN DEFAULT FALSE,
  ForgotPassword          BOOLEAN DEFAULT FALSE,
  TokenTimestamp          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    CHECK (TokenTimestamp > '2018-01-01')
);

-- Define a unique index on the trimmed and lowercase values of the Username field
-- so that it matches the username that will be stored in the server
CREATE UNIQUE INDEX IF NOT EXISTS idx_Unique_Username 
  ON LearnSQL.UserData_t(LOWER(TRIM(Username)));


-- Define a unique index on the trimmed and lowercase values of the email field
CREATE UNIQUE INDEX IF NOT EXISTS idx_Unique_Email 
  ON LearnSQL.UserData_t(LOWER(TRIM(Email)));


-- Change table's owner and privileges so that only LearnSQl can use it
ALTER TABLE LearnSQL.UserData_t OWNER TO LearnSQL;
REVOKE ALL PRIVILEGES ON LearnSQl.UserData_t FROM PUBLIC;


-- Define a table of classes for this DB
--  a "ClassID" is a unique id that represents a classname plus a random ID
--  a "ClassName" is the classID without the random ID
--  a "Section" is used with other attributes to guarantee uniqueness of classes.
--  a "StartDate" is used along with other attributes to guarantee uniqueness of
--   classes and is currently used (for convenience) as a "Semester" attribute.
--  The "Password" field will be used for students to create their student
--   account in the classdb database
CREATE TABLE IF NOT EXISTS LearnSQL.Class_t (
  ClassID                 VARCHAR(63) NOT NULL PRIMARY KEY, 
  ClassName               VARCHAR(27) NOT NULL
                            CHECK(TRIM(ClassName) <> ''),  
  Section                 VARCHAR(30) NOT NULL
                            CHECK(TRIM(Section) <> ''), 
  Times                   VARCHAR(15) NOT NULL
                            CHECK(TRIM(Times) <> ''), 
  Days                    VARCHAR(7) NOT NULL
                            CHECK(TRIM(Days) <> ''), 
  StartDate               DATE NOT NULL, 
  EndDate                 DATE NOT NULL, 
  Password                VARCHAR(60)  NOT NULL
                            CHECK(TRIM(Password) <> '')  
);

-- Change table's owner and privileges so that only LearnSQl can use it
ALTER TABLE LearnSQL.Class_t OWNER TO LearnSQL;
REVOKE ALL PRIVILEGES ON LearnSQL.Class_t FROM PUBLIC;



-- Define a table that represents the relation between UserData and Class
--  a "Username" is a unique id that represents a human user from UserData table
--  a "ClassID" is a unique id that represents a class from Class table
--  "isTeacher" defines whether user is a teacher for that specific class
CREATE TABLE IF NOT EXISTS LearnSQL.Attends (
  ClassID                 VARCHAR(63) NOT NULL REFERENCES LearnSQL.Class_t,
  Username                VARCHAR(63) NOT NULL,
  isTeacher               BOOLEAN DEFAULT FALSE,
  PRIMARY KEY (ClassID, Username)
);

--Change table's owner and privileges so that only LearnSQl can use it
ALTER TABLE LearnSQL.Attends OWNER TO LearnSQL;
REVOKE ALL PRIVILEGES ON LearnSQL.Attends FROM PUBLIC;



-- Define a view to return Class data
--  This view has all attributes of LearnSQL.Class_t with an added derived attribute
--   "studentCount"
--  A "studentCount" represents the number of students in a class
CREATE OR REPLACE VIEW LearnSQL.Class AS
SELECT ClassID, ClassName, Section, Times, Days, StartDate, EndDate, Password,
  (
    SELECT COUNT(*)
    FROM LearnSQL.Attends
    WHERE Attends.ClassID = LearnSQL.Class_t.ClassID AND isTeacher = FALSE
  ) AS studentCount
FROM LearnSQL.Class_t;

-- Change table's owner and privileges so that only LearnSQl can use it
ALTER TABLE Learnsql.Class_t OWNER TO LearnSQL;
REVOKE ALL PRIVILEGES ON LearnSQL.Class FROM PUBLIC;



-- Define a view to return UserData data
-- This view has all attributes of LearnSQL.UserData_t with an added derived attribute
--  "isstudent"
-- The attribute "isstudent" represents if a student is taking a class
CREATE OR REPLACE VIEW LearnSQL.UserData AS 
SELECT Username, Fullname, Password, Email, Token, DateJoined, isTeacher,
       isAdmin, isVerified, ForgotPassword, TokenTimestamp,
EXISTS 
  (
    SELECT *
    FROM LearnSQL.Attends 
    WHERE Attends.Username = LearnSQL.UserData_t.Username AND Attends.isTeacher = FALSE
  ) AS isstudent
FROM LearnSQL.UserData_t;

-- Change table's owner and privileges so that only LearnSQl can use it
ALTER TABLE Learnsql.UserData OWNER TO LearnSQL;
REVOKE ALL PRIVILEGES ON Learnsql.UserData FROM PUBLIC;

COMMIT;