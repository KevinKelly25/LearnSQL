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


--Enable the pgcrypto extension for PostgreSQL for hashing and generating salts
CREATE EXTENSION IF NOT EXISTS pgcrypto;



--Define function to register a user. This function will create a role within
-- the database and also a user within the tables of the LearnSQL database.
--If any errors are encountered an exception will be raised and the function
-- will stop execution.
CREATE OR REPLACE FUNCTION
  LearnSQL.createUser(UserName  LearnSQL.UserData_t.UserName%Type,
                      FullName  LearnSQL.UserData_t.FullName%Type,
                      Password  LearnSQL.UserData_t.Password%Type,
                      Email     LearnSQL.UserData_t.Email%Type,
                      Token     LearnSQL.UserData_t.Token%Type,
                      isTeacher LearnSQL.UserData_t.isTeacher%Type DEFAULT FALSE,
                      isAdmin   LearnSQL.UserData_t.isAdmin%Type DEFAULT FALSE)
  RETURNS VOID AS
$$
DECLARE
  encryptedPassword VARCHAR(60); --hashed password to be stored in UserData_t
BEGIN
  --Check if username exists
  IF EXISTS (
             SELECT *
             FROM UserData_t
             WHERE UserData_t.UserName = $1
            ) THEN
    RAISE EXCEPTION 'Username Already Exists';
  END IF;


  --Check if Email exists
  IF EXISTS (
             SELECT *
             FROM UserData_t
             WHERE UserData_t.Email = $4
            ) THEN
    RAISE EXCEPTION 'Email Already Exists';
  END IF;

  --create "hashed" password using blowfish cipher.
  encryptedPassword = crypt($3, gen_salt('bf'));

  --Add user information to the LearnSQL UserData table
  INSERT INTO UserData_t VALUES (LOWER($1),$2,encryptedPassword,$4, $5, $6, $7);

  --create database user
  EXECUTE FORMAT('CREATE USER %s WITH ENCRYPTED PASSWORD %L',LOWER($1), $3);

END;
$$ LANGUAGE plpgsql;



--Define function to delete a user. This function will delete a role within
-- the database and also a user within the tables of the LearnSQL database. If
-- the "DatabasePassword" is not null, which it is by default, it will also drop 
-- all objects in all other ClassDB databases will be dropped. If user owns any
-- objects in non-ClassDB databases the drop will fail.
--If any errors are encountered an exception will be raised and the function
-- will stop execution.
CREATE OR REPLACE FUNCTION
  LearnSQL.dropUser(User LearnSQL.UserData_t.UserName%Type,
                    DatabasePassword VARCHAR DEFAULT NULL)
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
  IF $2 NOT NULL THEN
    IF NOT EXISTS (SELECT * FROM pg_catalog.pg_roles
                    WHERE rolname = $1
                  ) THEN
      RAISE EXCEPTION 'User does not exist in database';
    END IF;

    --TODO: add Schema qualifier once it is added to the attends table
    --This will drop all objects owned by that user in each ClassDB database it is
    -- in. This may cause cascade issues until ClassDB has Multi-DB remove User
    -- support.
    FOR temprow IN
      SELECT ClassID FROM Attends WHERE UserName = $1;
    LOOP
      SELECT *
      FROM dblink('user=postgres dbname='|| temprow.ClassID || ' password=' || $2, 
                  'DROP OWNED BY '|| $1)
      AS throwAway(blank VARCHAR(30));--needed for dblink but unused
    END LOOP;

    --Delete user from the database
    EXECUTE FORMAT('DROP USER %s',$1);
  END IF;


  --Delete user information to the LearnSQL UserData and Attends table
  DELETE FROM Attends WHERE UserName = $1;
  DELETE FROM UserData_t WHERE UserName = $1;

END;
$$ LANGUAGE plpgsql;


--This function is given a old username and a new username. It updates the role
-- and tables associated with the old username with the new username as long as
-- the new username is not already taken  
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



--This function updates the given user's password with a new password. Before
-- it applies the new password it checks to make sure the given old password 
-- matches the password stored in the database. 
CREATE OR REPLACE FUNCTION
  LearnSQL.changePassword(UserName     LearnSQL.UserData_t.Password%Type,
                          oldPassword  LearnSQL.UserData_t.Password%Type,
                          newPassword  LearnSQL.UserData_t.Password%Type)
  RETURNS VOID AS
$$
DECLARE
  encryptedPassword VARCHAR(60); --hashed password from UserData_t
BEGIN
  encryptedPassword = SELECT password FROM UserData_t WHERE UserName = $1;  

  IF (encryptedPassword = crypt($2, encryptedPassword)) )
    THEN
      --Update database rolename to the new value
      EXECUTE FORMAT('ALTER USER %s WITH PASSWORD %L',$1,$3);
    ELSE
      RAISE EXCEPTION 'Old Password Does Not Match';
  END IF;
END;
$$ LANGUAGE plpgsql;



--TODO: Update Comment
CREATE OR REPLACE FUNCTION
  LearnSQL.changePassword(UserName LearnSQL.UserData_t.UserName%Type,
                          oldPassword VARCHAR(256),
                          newPassword VARCHAR(256))
  RETURNS VOID AS
$$
BEGIN
  --Checks that old password matches the correct password before updating the
  -- old password. If wrong password is supplied an exception is raised.
  --We currently store the passwords with MD5. On postgres the table pg_authid
  -- stores these passwords. However, md5 is added to the beginning and before
  -- hashing the password the user's username is appended to password. 
  --Taken and modified from ClassDB testClassDBRoleMgmt.sql
  IF EXISTS (
      SELECT * FROM pg_catalog.pg_authid
      WHERE RolName = $1 AND (
            RolPassword = 'md5' || pg_catalog.MD5($2 || $1)
            OR (RolPassword IS NULL AND $2 IS NULL) )
      )
    THEN
      --Update database rolename to the new value
      EXECUTE FORMAT('ALTER USER %s WITH PASSWORD %L',$1,$3);
    ELSE
      RAISE EXCEPTION 'Old Password Does Not Match';
    END IF;
END;
$$ LANGUAGE plpgsql;



--TODO: Update Comment
CREATE OR REPLACE FUNCTION
  LearnSQL.changeFullName(userName LearnSQL.UserData_t.UserName%Type,
                          newFullName LearnSQL.UserData_t.FullName%Type)
  RETURNS VOID AS
$$
BEGIN
  UPDATE UserData_t SET FullName = $2 WHERE UserName = $1;
END;
$$ LANGUAGE plpgsql;



--TODO: Update Comment
CREATE OR REPLACE FUNCTION
  LearnSQL.changeEmail(userName LearnSQL.UserData_t.UserName%Type,
                       Email LearnSQL.UserData_t.Email%Type)
  RETURNS VOID AS
$$
BEGIN
  UPDATE UserData_t SET Email = $2 WHERE UserName = $1;
END;
$$ LANGUAGE plpgsql;




COMMIT;