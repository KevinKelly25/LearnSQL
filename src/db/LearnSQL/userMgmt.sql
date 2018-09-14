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



--Define function to register a user. This function will create a role within
-- the database and also a user within the tables of the LearnSQL database.
--If any errors are encountered an exception will be raised and the function
-- will stop execution.
CREATE OR REPLACE FUNCTION
  LearnSQL.createUser(UserName  LearnSQL.UserData_t.UserName%Type,
                      FullName  LearnSQL.UserData_t.FullName%Type,
                      Password  VARCHAR(319),
                      Email     VARCHAR(319),
                      isTeacher LearnSQL.UserData_t.isTeacher%Type DEFAULT FALSE,
                      isAdmin   LearnSQL.UserData_t.isAdmin%Type DEFAULT FALSE)
   RETURNS VOID AS
$$
DECLARE
  Token VARCHAR(60);--token to be stored for email validation
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


  --SELECT MD5(random()::text) generated a random token that will be used for
  -- email validation.
  Token = SELECT MD5(random()::text);

  --Add user information to the LearnSQL UserData table
  INSERT INTO UserData_t VALUES ($1,$2,$3,$4, Token, $5, $6);

  --create database user
  EXECUTE FORMAT('CREATE USER %s WITH ENCRYPTED PASSWORD %L',$1, $3);

END;
$$ LANGUAGE plpgsql;



--Define function to delete a user. This function will delete a role within
-- the database and also a user within the tables of the LearnSQL database.
--If any errors are encountered an exception will be raised and the function
-- will stop execution.
CREATE OR REPLACE FUNCTION
  LearnSQL.dropUser(UserName LearnSQL.UserData_t.UserName%Type,
                    dropFromServer DEFAULT TRUE)
   RETURNS VOID AS
$$
BEGIN
  --Check if username exists in LearnSQL tables
  IF NOT EXISTS (SELECT *
                 FROM UserData_t
                 WHERE UserData_t.UserName = $1
                ) THEN
    RAISE EXCEPTION 'User does not exist in tables';
  END IF;

  --Check if user exists in database
  IF $2 THEN
    IF NOT EXISTS (SELECT * FROM pg_catalog.pg_roles
                    WHERE rolname = $1
                  ) THEN
      RAISE EXCEPTION 'User does not exist in database';
    END IF;

    --Delete user from the database
    EXECUTE FORMAT('DROP USER %s',$1);
  END IF;


  --Delete user information to the LearnSQL UserData and Attends table
  DELETE FROM Attends WHERE UserName = $1;
  DELETE FROM UserData_t WHERE UserName = $1;

END;
$$ LANGUAGE plpgsql;


--Define function to delete a user. This function will delete a role within
-- the database and also a user within the tables of the LearnSQL database.
--If any errors are encountered an exception will be raised and the function
-- will stop execution.
CREATE OR REPLACE FUNCTION
  LearnSQL.changeUsername(oldUserName LearnSQL.UserData_t.UserName%Type,
                          newUserName LearnSQL.UserData_t.UserName%Type)
   RETURNS VOID AS
$$
BEGIN

  --check if new username is already taken
  IF EXISTS (SELECT *
             FROM UserData_t
             WHERE UserData_t.UserName = $2
            ) THEN
    RAISE EXCEPTION 'New username already exists';
  END IF;

  --Check if username exists in LearnSQL tables
  IF NOT EXISTS (SELECT *
                 FROM UserData_t
                 WHERE UserData_t.UserName = $1
                ) THEN
    RAISE EXCEPTION 'User does not exist in tables';
  END IF;

  --Update database rolename to the new value
  EXECUTE FORMAT('ALTER USER %s RENAME TO %s',$1,$2);
  
  --Update tables to reflect new username
  UPDATE LearnSQL.UserData_t 
  SET UserName = $2
  WHERE UserName = $1;
 
END;
$$ LANGUAGE plpgsql;




COMMIT;