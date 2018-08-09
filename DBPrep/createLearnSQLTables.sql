CREATE TABLE IF NOT EXISTS UserData (
  Username                VARCHAR(256) NOT NULL PRIMARY KEY,
  FullName                VARCHAR(256) NOT NULL,
  Password                VARCHAR(256) NOT NULL,
  Email                   VARCHAR(319) NOT NULL CHECK(TRIM(Email) like '_%@_%._%'),
  DateJoined              DATE DEFAULT CURRENT_DATE,
  isTeacher               BOOLEAN DEFAULT FALSE,
  isAdmin                 BOOLEAN DEFAULT FALSE
);

CREATE UNIQUE INDEX idx_Unique_Email ON UserData(LOWER(TRIM(Email)));

CREATE TABLE IF NOT EXISTS Class (
  ClassID                 VARCHAR(60) NOT NULL PRIMARY KEY,
  ClassName               VARCHAR(60),
  Password                VARCHAR(60)
);

CREATE TABLE IF NOT EXISTS Attends (
  ClassID                 VARCHAR(30) NOT NULL REFERENCES Class,
  Username                  VARCHAR(30) NOT NULL REFERENCES UserData,
  isTeacher               BOOLEAN,
  PRIMARY KEY (ClassID, Username)
);

--Grant appropriate privileges to different roles to the current database
DO
$$
DECLARE
   currentDB VARCHAR(128);
BEGIN
   currentDB := current_database();

   --Disallow DB connection to all users
   -- Postgres grants CONNECT to all by default
   EXECUTE format('REVOKE CONNECT ON DATABASE %I FROM PUBLIC', currentDB);

   --Let only app-specific roles connect to the DB
   -- no need for ClassDB to connect to the DB
   EXECUTE format('GRANT CONNECT ON DATABASE %I TO ClassDB_Instructor, '
                  'ClassDB_Student, ClassDB_DBManager', currentDB);

   --Allow ClassDB and ClassDB users to create schemas on the current database
   EXECUTE format('GRANT CREATE ON DATABASE %I TO ClassDB, ClassDB_Instructor,'
                  ' ClassDB_DBManager, ClassDB_Student', currentDB);
END
$$;


--Grant ClassDB to the current user
-- allows altering privileges of objects, even after being owned by ClassDB
GRANT ClassDB TO CURRENT_USER;

--Prevent users who are not instructors from modifying the public schema
-- public schema contains objects and functions students can read
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT CREATE ON SCHEMA public TO ClassDB_Instructor;

--Create a schema to hold app's admin info and assign privileges on that schema
CREATE SCHEMA IF NOT EXISTS classdb AUTHORIZATION ClassDB;
GRANT USAGE ON SCHEMA classdb TO ClassDB_Instructor, ClassDB_DBManager;
