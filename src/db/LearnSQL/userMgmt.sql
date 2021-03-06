-- userMgmt.sql - LearnSQL

-- Kevin Kelly
-- Web Applications and Databases for Education (WADE)

-- This file creates the functions involved with user management in the LearnSQL
--  database.This file should be run after createLearnSQLTables.sql



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



-- Suppress NOTICEs for this script only, this will not apply to functions
--  defined within. This hides unimportant, but possibly confusing messages
SET LOCAL client_min_messages TO WARNING;



-- Define a view to return all users who are students.
--  A user is determined to be a student if the isStudent flag in Userdata is 
--  true. This flag is true when a student attends any class and is not the
--  Teacher.
CREATE OR REPLACE VIEW LearnSQL.Student AS 
SELECT Username, Fullname, Password, Email
FROM LearnSQL.UserData
WHERE isStudent = TRUE;



-- Define a view to return all users who are Teacher.
--  A user is determined to be a Teacher if the isTeacher flag in Userdata 
--  is true. 
CREATE OR REPLACE VIEW LearnSQL.Teacher AS 
SELECT Username, Fullname, Password, Email
FROM LearnSQL.UserData_t
WHERE isTeacher = TRUE;



-- Define a view to return all users who are admins.
--  A user is determined to be an admin if the isAdmin flag in userdata is true.
CREATE OR REPLACE VIEW LearnSQL.Admin AS 
SELECT Username, Fullname, Password, Email
FROM LearnSQL.UserData_t
WHERE isAdmin = TRUE;



-- Enable the pgcrypto extension for PostgreSQL for hashing and generating salts
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA LearnSQL;
CREATE EXTENSION IF NOT EXISTS dblink WITH SCHEMA LearnSQL;



-- Define function to register a user. This function will create a role within
--  the database and also a user within the tables of the LearnSQL database
-- If any errors are encountered an exception will be raised and the function
--  will stop execution
CREATE OR REPLACE FUNCTION LearnSQL.createUser(
  userName    LearnSQL.UserData_t.UserName%Type,
  fullName    LearnSQL.UserData_t.FullName%Type,
  password    LearnSQL.UserData_t.Password%Type,
  email       LearnSQL.UserData_t.Email%Type,
  token       LearnSQL.UserData_t.Token%Type,
  isTeacher   LearnSQL.UserData_t.isTeacher%Type DEFAULT FALSE,
  isAdmin     LearnSQL.UserData_t.isAdmin%Type DEFAULT FALSE)

RETURNS VOID AS
$$
DECLARE
  encryptedPassword VARCHAR(60); -- Hashed password to be stored in UserData_t
  encryptedToken VARCHAR(60); -- Hashed password to be stored in UserData_t
BEGIN
  -- Create "hashed" password using blowfish cipher
  encryptedPassword = LearnSQL.crypt($3, LearnSQL.gen_salt('bf'));

  -- Create "hashed" token using blowfish cipher
  encryptedToken = LearnSQL.crypt($5, LearnSQL.gen_salt('bf'));

  -- Add user information to the LearnSQL UserData table
  INSERT INTO LearnSQL.UserData_t VALUES (LOWER($1),$2,encryptedPassword,$4,
                                          encryptedToken, $6, $7);

  -- Create database user
  EXECUTE FORMAT('CREATE USER %s WITH ENCRYPTED PASSWORD %L',LOWER($1), $3);

END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER;

-- Change function's owner and privileges so that only LearnSQl can use it
ALTER FUNCTION 
  LearnSQL.createUser(LearnSQL.UserData_t.UserName%Type, 
                      LearnSQL.UserData_t.FullName%Type,
                      LearnSQL.UserData_t.Password%Type,
                      LearnSQL.UserData_t.Email%Type,
                      LearnSQL.UserData_t.Token%Type,
                      LearnSQL.UserData_t.isTeacher%Type,
                      LearnSQL.UserData_t.isAdmin%Type
                     ) 
  OWNER TO LearnSQL;
REVOKE ALL ON FUNCTION 
    LearnSQL.createUser(LearnSQL.UserData_t.UserName%Type, 
                        LearnSQL.UserData_t.FullName%Type,
                        LearnSQL.UserData_t.Password%Type,
                        LearnSQL.UserData_t.Email%Type,
                        LearnSQL.UserData_t.Token%Type,
                        LearnSQL.UserData_t.isTeacher%Type,
                        LearnSQL.UserData_t.isAdmin%Type
                       )
    FROM PUBLIC;



-- Define function to delete a user. This function will delete a role within
--  the database and also a user within the tables of the LearnSQL database. If
--  the "DatabasePassword" is not null, which it is by default, it will also drop 
--  all objects in all other ClassDB databases will be dropped. If user owns any
--  objects in non-ClassDB databases the drop will fail
-- If any errors are encountered an exception will be raised and the function
--  will stop execution
CREATE OR REPLACE FUNCTION LearnSQL.dropUser(
  username           LearnSQL.UserData_t.UserName%Type,
  databaseUsername   VARCHAR DEFAULT NULL,
  databasePassword   VARCHAR DEFAULT NULL)

RETURNS VOID AS
$$
DECLARE
    rec RECORD;
BEGIN
  -- Check if username exists in LearnSQL tables
  IF NOT EXISTS (
                  SELECT *
                  FROM LearnSQL.UserData_t
                  WHERE UserData_t.UserName = $1
                ) 
  THEN
    RAISE EXCEPTION 'User does not exist in tables';
  END IF;

  -- Check if user exists in database
  IF ($2 IS NOT NULL AND $3 IS NOT NULL) THEN
    IF NOT EXISTS (
                    SELECT * FROM pg_catalog.pg_roles
                    WHERE rolname = $1
                  ) 
    THEN
      RAISE EXCEPTION 'User does not exist in database';
    END IF;

    -- This will drop all objects owned by that user in each ClassDB database it is
    --  in. This may cause cascade issues until ClassDB has Multi-DB remove User
    --  support
    FOR rec IN
      SELECT ClassID FROM LearnSQL.Attends WHERE Attends.UserName = $1
    LOOP
      SELECT *
      FROM dblink_exec('user='|| $2 ||' dbname='|| rec.ClassID || ' password=' || $3, 
                       'DROP OWNED BY '|| $1);
    END LOOP;

    -- Delete user from the database
    EXECUTE FORMAT('DROP USER %s',$1);
  END IF;


  -- Delete user information to the LearnSQL UserData and Attends table
  DELETE FROM LearnSQL.Attends WHERE Attends.UserName = $1;
  DELETE FROM LearnSQL.UserData_t WHERE UserData_t.UserName = $1;

END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER;

-- Change function's owner and privileges so that only LearnSQl can use it
ALTER FUNCTION 
  LearnSQL.dropUser(LearnSQL.UserData_t.UserName%Type, VARCHAR, VARCHAR) 
  OWNER TO LearnSQL;

REVOKE ALL ON FUNCTION 
    LearnSQL.dropUser(LearnSQL.UserData_t.UserName%Type, VARCHAR, VARCHAR)
    FROM PUBLIC;




-- This function is given a old username and a new username. It updates the role
--  and tables associated with the old username with the new username as long as
--  the new username is not already taken  
CREATE OR REPLACE FUNCTION LearnSQL.changeUsername(
  oldUserName   LearnSQL.UserData_t.UserName%Type,
  newUserName   LearnSQL.UserData_t.UserName%Type)

RETURNS VOID AS
$$
BEGIN
  -- Update database rolename to the new value
  EXECUTE FORMAT('ALTER USER %s RENAME TO %s',$1,$2);
  
  -- Update tables to reflect new username
  UPDATE LearnSQL.UserData_t 
  SET UserName = $2
  WHERE UserName = $1;
 
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER;

-- Change function's owner and privileges so that only LearnSQl can use it
ALTER FUNCTION 
  LearnSQL.changeUsername(LearnSQL.UserData_t.UserName%Type,
                          LearnSQL.UserData_t.UserName%Type) 
  OWNER TO LearnSQL;

REVOKE ALL ON FUNCTION 
  LearnSQL.changeUsername(LearnSQL.UserData_t.UserName%Type,
                          LearnSQL.UserData_t.UserName%Type) 
  FROM PUBLIC;



-- This function updates the given user's password with a new password. Before
--  it applies the new password it checks to make sure the given old password 
--  matches the password stored in the database 
CREATE OR REPLACE FUNCTION
  LearnSQL.changePassword(userName     LearnSQL.UserData_t.UserName%Type,
                          oldPassword  LearnSQL.UserData_t.Password%Type,
                          newPassword  LearnSQL.UserData_t.Password%Type)
  RETURNS VOID AS
$$
DECLARE
  encryptedPassword VARCHAR(60); -- Hashed password from UserData_t
BEGIN
  SELECT password INTO encryptedPassword
  FROM LearnSQL.UserData_t 
  WHERE UserData_t.UserName = $1;  

  IF (encryptedPassword = LearnSQL.crypt($2, encryptedPassword)) 
    THEN
      -- Update database rolename to the new value
      EXECUTE FORMAT('ALTER USER %s WITH PASSWORD %L',$1,$3);

      -- Update LearnSQL database password
      UPDATE LearnSQL.UserData_t 
      SET Password = LearnSQL.crypt($3, LearnSQL.gen_salt('bf'))
      WHERE UserData_t.Username = $1;
    ELSE
      RAISE EXCEPTION 'Old Password Does Not Match';
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER;

-- Change function's owner and privileges so that only LearnSQl can use it
ALTER FUNCTION 
  LearnSQL.changePassword(LearnSQL.UserData_t.UserName%Type,
                          LearnSQL.UserData_t.Password%Type,
                          LearnSQL.UserData_t.Password%Type) 
  OWNER TO LearnSQL;

REVOKE ALL ON FUNCTION 
  LearnSQL.changePassword(LearnSQL.UserData_t.UserName%Type,
                          LearnSQL.UserData_t.Password%Type,
                          LearnSQL.UserData_t.Password%Type) 
  FROM PUBLIC;



-- This function updates the given username with the given Full Name
CREATE OR REPLACE FUNCTION LearnSQL.changeFullName(
  userName      LearnSQL.UserData_t.UserName%Type,
  newFullName   LearnSQL.UserData_t.FullName%Type)

RETURNS VOID AS
$$
BEGIN
  UPDATE LearnSQL.UserData_t SET FullName = $2 WHERE UserData_t.UserName = $1;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER;

-- Change function's owner and privileges so that only LearnSQl can use it
ALTER FUNCTION 
  LearnSQL.changeFullName(LearnSQL.UserData_t.UserName%Type,
                          LearnSQL.UserData_t.FullName%Type) 
  OWNER TO LearnSQL;

REVOKE ALL ON FUNCTION 
  LearnSQL.changeFullName(LearnSQL.UserData_t.UserName%Type,
                          LearnSQL.UserData_t.FullName%Type) 
  FROM PUBLIC;



-- This function updates the given username with the given Email
CREATE OR REPLACE FUNCTION LearnSQL.changeEmail(
  userName   LearnSQL.UserData_t.UserName%Type,
  email      LearnSQL.UserData_t.Email%Type)

RETURNS VOID AS
$$
BEGIN
  UPDATE LearnSQL.UserData_t SET email = $2 WHERE UserData_t.UserName = $1;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER;

-- Change function's owner and privileges so that only LearnSQl can use it
ALTER FUNCTION 
  LearnSQL.changeEmail(LearnSQL.UserData_t.UserName%Type,
                       LearnSQL.UserData_t.Email%Type) 
  OWNER TO LearnSQL;

REVOKE ALL ON FUNCTION 
  LearnSQL.changeEmail(LearnSQL.UserData_t.UserName%Type,
                       LearnSQL.UserData_t.Email%Type) 
  FROM PUBLIC;



-- This function resets the password of a user as long as the token is correct
--  for the given user. When given a username it extracts
--  what is supposed to be the correct hashed token and compares the given token
--  to the hashed token. If matched and forgotPassword is true the password is
--  updated to the given new password
CREATE OR REPLACE FUNCTION LearnSQL.forgotPasswordReset(
  userName      LearnSQL.UserData_t.UserName%Type,
  token         LearnSQL.UserData_t.Token%Type,
  newPassword   LearnSQL.UserData_t.Token%Type)

RETURNS VOID AS
$$
DECLARE
  encryptedPassword VARCHAR(60); -- Hashed password to be stored in UserData_t
  hashedToken VARCHAR(60); -- Hashed token that was stored in UserData_t
BEGIN
  -- Check to make sure the user token has not expired
  IF EXISTS (
              SELECT 1 FROM LearnSQL.UserData_t 
              WHERE UserData_t.UserName = $1 
              AND UserData_t.TokenTimestamp < now() - '30 minutes'::interval
            )
  THEN
    RAISE EXCEPTION 'Token has expired';
  END IF;
  
  -- Retrieve the hashed token that was stored in the UserData when
  SELECT UserData_t.Token INTO hashedToken
  FROM LearnSQL.UserData_t 
  WHERE UserData_t.UserName = $1; 

  -- Check if the given token and the username is correct
  IF (hashedToken = LearnSQL.crypt($2, hashedToken))
  THEN
    -- Create "hashed" password using blowfish cipher
    encryptedPassword = LearnSQL.crypt($3, LearnSQL.gen_salt('bf'));

    -- Update UserData_t with the new password
    UPDATE LearnSQL.UserData_t 
    SET Password = encryptedPassword, ForgotPassword = FALSE
    WHERE UserData_t.UserName = $1;

    -- Update database rolename to the new value
    EXECUTE FORMAT('ALTER USER %s WITH PASSWORD %L',$1,$3);
  
  ELSE
    RAISE EXCEPTION 'Token is incorrect';
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER;

-- Change function's owner and privileges so that only LearnSQl can use it
ALTER FUNCTION 
  LearnSQL.forgotPasswordReset(LearnSQL.UserData_t.UserName%Type,
                               LearnSQL.UserData_t.Token%Type,
                               LearnSQL.UserData_t.Token%Type) 
  OWNER TO LearnSQL;

REVOKE ALL ON FUNCTION 
  LearnSQL.forgotPasswordReset(LearnSQL.UserData_t.UserName%Type,
                               LearnSQL.UserData_t.Token%Type,
                               LearnSQL.UserData_t.Token%Type) 
  FROM PUBLIC;



-- Define a function returns a boolean value on whether user is a student
CREATE OR REPLACE FUNCTION LearnSQL.isStudent(
  userName   LearnSQL.UserData_t.UserName%Type)

RETURNS BOOLEAN AS
$$
BEGIN
  IF EXISTS (
              SELECT 1 FROM LearnSQL.UserData_t 
              WHERE UserData_t.UserName = $1 
              AND UserData_t.isStudent = TRUE
            )
  THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Change function's owner and privileges so that only LearnSQl can use it
ALTER FUNCTION 
  LearnSQL.isStudent(LearnSQL.UserData_t.UserName%Type) 
  OWNER TO LearnSQL;

REVOKE ALL ON FUNCTION 
  LearnSQL.isStudent(LearnSQL.UserData_t.UserName%Type) 
  FROM PUBLIC;



-- Define a function returns a boolean value on whether user is a teacher
CREATE OR REPLACE FUNCTION LearnSQL.isTeacher(
  userName   LearnSQL.UserData_t.UserName%Type)

RETURNS BOOLEAN AS
$$
BEGIN
  IF EXISTS (
              SELECT 1 FROM LearnSQL.UserData_t 
              WHERE UserData_t.UserName = $1 
              AND UserData_t.isTeacher = TRUE
            )
  THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Change function's owner and privileges so that only LearnSQl can use it
ALTER FUNCTION 
  LearnSQL.isTeacher(LearnSQL.UserData_t.UserName%Type) 
  OWNER TO LearnSQL;

REVOKE ALL ON FUNCTION 
  LearnSQL.isTeacher(LearnSQL.UserData_t.UserName%Type) 
  FROM PUBLIC;



-- Define a function returns a boolean value on whether user is an admin
CREATE OR REPLACE FUNCTION LearnSQL.isAdmin(
  userName   LearnSQL.UserData_t.UserName%Type)
  
RETURNS BOOLEAN AS
$$
BEGIN
  IF EXISTS (
              SELECT 1 FROM LearnSQL.UserData_t 
              WHERE UserData_t.UserName = $1 
              AND UserData_t.isAdmin = TRUE
            )
  THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Change function's owner and privileges so that only LearnSQl can use it
ALTER FUNCTION 
  LearnSQL.isAdmin(LearnSQL.UserData_t.UserName%Type) 
  OWNER TO LearnSQL;

REVOKE ALL ON FUNCTION 
  LearnSQL.isAdmin(LearnSQL.UserData_t.UserName%Type) 
  FROM PUBLIC;



COMMIT;