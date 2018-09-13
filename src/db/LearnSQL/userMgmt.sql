-- userMgmt.sql - LearnSQL

-- Kevin Kelly
-- Web Applications and Databases for Education (WADE)

-- This file creates the functions involved with user management in the LearnSQL
--  database.This file should be run after createLearnSQLTables.sql

START TRANSACTION;


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