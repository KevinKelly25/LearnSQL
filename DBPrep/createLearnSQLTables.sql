-- createLearnSQLTables.sql - LearnSQL

-- Kevin Kelly
-- Web Applications and Databases for Education (WADE)

-- This file supplies the tables and unique index for the backend of the LearnSQL
--  website.


-- Define a table of userdata for this DB
--  a "Username" is a unique id that represents a human user
--  a "Password" represents the hashed and salted password of a user
--  the "Email" field characters are check to make sure they follow the scheme
--   of a valid email
CREATE TABLE IF NOT EXISTS UserData (
  Username                VARCHAR(256) NOT NULL PRIMARY KEY,
  FullName                VARCHAR(256) NOT NULL,
  Password                VARCHAR(60) NOT NULL,
  Email                   VARCHAR(319) NOT NULL CHECK(TRIM(Email) like '_%@_%._%'),
  DateJoined              DATE DEFAULT CURRENT_DATE,
  isTeacher               BOOLEAN DEFAULT FALSE,
  isAdmin                 BOOLEAN DEFAULT FALSE,
  isVerified              BOOLEAN DEFAULT FALSE,
  Token                   VARCHAR(60),
  ForgotPassword          BOOLEAN DEFAULT FALSE
);



-- Define a unique index on the trimmer and lowercase values of the email field
CREATE UNIQUE INDEX idx_Unique_Email ON UserData(LOWER(TRIM(Email)));


-- Define a table of classes for this DB
--  a "ClassID" is a unique id that represents a classname plus a random ID
--  a "ClassName" is the classID without the random ID
--  the "Password" field will be used for students to create thier student
--   account in the classdb database
CREATE TABLE IF NOT EXISTS Class (
  ClassID                 VARCHAR(256) NOT NULL PRIMARY KEY,
  ClassName               VARCHAR(236),
  Password                VARCHAR(60)
);



-- Define a table that represents the relation between UserData and Class
--  a "Username" is a unique id that represents a human user from UserData table
--  a "ClassID" is a unique id that represents a class from Class table
--  "isTeacher" defines whether user is a teacher for that specific class
CREATE TABLE IF NOT EXISTS Attends (
  ClassID                 VARCHAR(256) NOT NULL REFERENCES Class,
  Username                VARCHAR(256) NOT NULL REFERENCES UserData,
  isTeacher               BOOLEAN,
  PRIMARY KEY (ClassID, Username)
);
