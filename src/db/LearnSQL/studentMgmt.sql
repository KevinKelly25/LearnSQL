-- studentMgmt.sql - LearnSQL

-- Christopher Innaco
-- Web Applications and Databases for Education (WADE)

-- This file creates the functions involved with student enrollment in the LearnSQL
--  database.

START TRANSACTION;

--Make sure the current user has sufficient privilege to run this script
-- Privilege required: superuser

DO
$$
BEGIN
  IF NOT EXISTS (
                  SELECT * FROM pg_catalog.pg_roles
                  WHERE rolname = CURRENT_USER AND rolsuper = TRUE
                ) THEN
      RAISE EXCEPTION 'Insufficient privileges: User must hold superuser '
                      'permissions to execute this script';
   END IF;
END
$$;


--Suppress NOTICEs for this script only, this will not apply to functions
-- defined within. This hides unimportant, and possibly confusing messages
SET LOCAL client_min_messages TO WARNING;


CREATE OR REPLACE FUNCTION
  LearnSQL.getClasses(studentName  LearnSQL.UserData_t.UserName%Type)

  RETURNS TABLE (
                  ClassName     LearnSQL.Class_t.ClassName%Type,
                  Section       LearnSQL.Class_t.Section%Type,
                  Times         LearnSQL.Class_t.Times%Type,
                  Days          LearnSQL.Class_t.Days%Type,
                  StartDate     LearnSQL.Class_t.StartDate%Type,
                  EndDate       LearnSQL.Class_t.EndDate%Type,
                  StudentCount  LearnSQL.Class.StudentCount%Type
                ) AS

$$
DECLARE
  
BEGIN
  -- Check if the user is enrolled in at least one class
  IF NOT EXISTS (
                  RETURN QUERY SELECT ClassName, Section, Times, Days, StartDate,
                  EndDate, StudentCount 
                  FROM Attends INNER JOIN Class ON Attends.ClassID = Class.ClassID 
                  WHERE Username = studentName AND isTeacher = false
                ) THEN
    RAISE EXCEPTION 'User is not enrolled in any classes';
  END IF;



/*ClassName     LearnSQL.Class_t.ClassName%Type,
                  Section       LearnSQL.Class_t.Section%Type,
                  Times         LearnSQL.Class_t.Times%Type,
                  Days          LearnSQL.Class_t.Days%Type,
                  StartDate     LearnSQL.Class_t.StartDate%Type,
                  EndDate       LearnSQL.Class_t.EndDate%Type,
                  StudentCount  LearnSQL.Class_t.StudentCount%Type*/

  --Check if Email exists
 /* IF EXISTS (
             SELECT *
             FROM LearnSQL.UserData_t
             WHERE UserData_t.Email = $4
            ) THEN
    RAISE EXCEPTION 'Email Already Exists';
  END IF;

  --Add user information to the LearnSQL UserData table
  INSERT INTO LearnSQL.UserData_t VALUES (LOWER($1),$2,encryptedPassword,$4,
                                          encryptedToken, $6, $7);

  --Create database user
  EXECUTE FORMAT('CREATE USER %s WITH ENCRYPTED PASSWORD %L',LOWER($1), $3);*/

END;
$$ LANGUAGE plpgsql;

/*
--Define function to register a user. This function will create a role within
-- the database and also a user within the tables of the LearnSQL database.
--If any errors are encountered an exception will be raised and the function
-- will stop execution.
CREATE OR REPLACE FUNCTION
  LearnSQL.createUser(userName  LearnSQL.UserData_t.UserName%Type,
                      fullName  LearnSQL.UserData_t.FullName%Type,
                      password  LearnSQL.UserData_t.Password%Type,
                      email     LearnSQL.UserData_t.Email%Type,
                      token     LearnSQL.UserData_t.Token%Type,
                      isTeacher LearnSQL.UserData_t.isTeacher%Type DEFAULT FALSE,
                      isAdmin   LearnSQL.UserData_t.isAdmin%Type DEFAULT FALSE)
  RETURNS VOID AS
$$
DECLARE
  encryptedPassword VARCHAR(60); --hashed password to be stored in UserData_t
  encryptedToken VARCHAR(60); --hashed password to be stored in UserData_t
BEGIN
  --Check if username exists
  IF EXISTS (
             SELECT *
             FROM LearnSQL.UserData_t
             WHERE UserData_t.UserName = $1
            ) THEN
    RAISE EXCEPTION 'Username Already Exists';
  END IF;


  --Check if Email exists
  IF EXISTS (
             SELECT *
             FROM LearnSQL.UserData_t
             WHERE UserData_t.Email = $4
            ) THEN
    RAISE EXCEPTION 'Email Already Exists';
  END IF;

  --Create "hashed" password using blowfish cipher.
  encryptedPassword = crypt($3, gen_salt('bf'));

  --Create "hashed" token using blowfish cipher.
  encryptedToken = crypt($5, gen_salt('bf'));

  --Add user information to the LearnSQL UserData table
  INSERT INTO LearnSQL.UserData_t VALUES (LOWER($1),$2,encryptedPassword,$4,
                                          encryptedToken, $6, $7);

  --Create database user
  EXECUTE FORMAT('CREATE USER %s WITH ENCRYPTED PASSWORD %L',LOWER($1), $3);

END;
$$ LANGUAGE plpgsql;
*/

COMMIT;