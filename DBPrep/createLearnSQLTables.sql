-- createLearnSQLTables.sql - LearnSQL

-- Kevin Kelly, Michael Torres
-- Web Applications and Databases for Education (WADE)

-- This file supplies the tables and unique index for the backend of the LearnSQL
--  website.


-- Define a table of userdata for this DB
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
CREATE UNIQUE INDEX idx_Unique_Email ON UserData(LOWER(TRIM(Email)));



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
  Username                VARCHAR(256) NOT NULL REFERENCES UserData,
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