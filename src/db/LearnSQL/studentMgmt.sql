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
                  SELECT 1 FROM pg_catalog.pg_roles
                  WHERE rolname = CURRENT_USER AND rolsuper = TRUE
                ) 
    THEN
      RAISE EXCEPTION 'Insufficient privileges: User must hold superuser '
                      'permissions to execute this script';
   END IF;
END
$$;

-- Allow for cross-database queries using the `dblink` extension on the 'LearnSQL'
--  schema

--CREATE EXTENSION IF NOT EXISTS dblink SCHEMA LearnSQL;

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
                  StudentCount  LearnSQL.Class.StudentCount%Type,
                  isTeacher     LearnSQL.Attends.isTeacher%Type
                ) 
    AS

$$
BEGIN

IF NOT EXISTS (
                SELECT 1
                FROM LearnSQL.Attends
                WHERE LearnSQL.Attends.userName = $1
              )
  THEN  
    RAISE EXCEPTION 'User is not enrolled in any classes';     

END IF;
     
  RETURN QUERY    
  SELECT LearnSQL.Class.ClassName, 
         LearnSQL.Class.Section, 
         LearnSQL.Class.Times, 
         LearnSQL.Class.Days, 
         LearnSQL.Class.StartDate,
         LearnSQL.Class.EndDate, 
         LearnSQL.Class.StudentCount, 
         LearnSQL.Attends.isTeacher 
  FROM LearnSQL.Attends INNER JOIN LearnSQL.Class 
  ON LearnSQL.Attends.ClassID = LearnSQL.Class.ClassID 
  WHERE LearnSQL.Attends.Username = $1;

END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION
  LearnSQL.joinClass( userName          LearnSQL.Attends.userName%Type, 
                      userFullName      LearnSQL.UserData_t.fullName%Type,
                      userPassword      LearnSQL.UserData_t.password%Type,
                      classID           LearnSQL.Attends.classID%Type,
                      classPassword     LearnSQL.Class_t.password%Type,
                      databaseUsername  VARCHAR(63),
                      databasePassword  VARCHAR(64),
                      adminUserName     LearnSQL.UserData_t.userName%Type 
                                        DEFAULT NULL,
                      adminPassword     LearnSQL.UserData_t.password%Type
                                        DEFAULT NULL)
  RETURNS VOID AS

$$
DECLARE

  storedClassPassword  LearnSQL.Class_t.password%Type;
  checkAdminQuery      TEXT;
  checkAdminPassword   BOOLEAN;
  isAdmin              BOOLEAN;
  addStudentQuery      TEXT;

BEGIN

  isAdmin := FALSE;
  
  -- If an administrator's username is supplied, check if the user holds that role
  --  and if the password is correct
  IF $8 IS NOT NULL
    THEN
      checkAdminQuery := ' SELECT ClassDB.isMember('''|| adminUserName ||''', ''classdb_admin'') ';

      SELECT *
      INTO isAdmin
      FROM LearnSQL.dblink('user='      || $6 || 
                           ' password=' || $7 || 
                           ' dbname='   || $4, checkAdminQuery)
      AS throwAway(blank VARCHAR(30)); -- Unused return variable for `dblink`

      SELECT 1
      INTO checkAdminPassword
      FROM LearnSQL.UserData_t
      WHERE LearnSQL.UserData_t.password = $9
      AND LearnSQL.UserData_t.userName = $8;

      IF ((isAdmin IS FALSE) OR (checkAdminPassword IS FALSE))
        THEN
          RAISE EXCEPTION 'The user does not have the permissions necessary to enroll other students';
      END IF;

  END IF;

  -- Check if the student is already a member of the class
  IF EXISTS (
              SELECT 1
              FROM LearnSQL.Attends
              WHERE LearnSQL.Attends.userName = $1
              AND LearnSQL.Attends.classID = $4
            ) 
    THEN
      RAISE EXCEPTION 'Student is already a member of the specified class';

  END IF;

  -- Check if the given password matches the stored password.
  -- Allows for users to join classes for which no password is set.
  -- Allows administrators to force a student to enroll in a class.
  IF $5 IS NOT NULL OR isAdmin IS TRUE
    THEN
      SELECT password
      INTO storedClassPassword
      FROM LearnSQL.Class
      WHERE Class.classID = $4;

      IF storedClassPassword = $5  OR isAdmin IS TRUE 
        THEN

          -- Add the student to the class
          INSERT INTO LearnSQL.Attends VALUES($4, $1, 'FALSE');

          -- Create the user under the ClassDB student role using a cross-
          -- database query

          addStudentQuery := ' SELECT ClassDB.createStudent('''|| userName ||''','''|| userFullName ||''') ';

          PERFORM *
          FROM LearnSQL.dblink('user='      || $6 || 
                              ' password=' || $7 || 
                              ' dbname='   || $4, addStudentQuery)
          AS throwAway(blank VARCHAR(30)); -- Unused return variable for `dblink`

      ELSE
        RAISE EXCEPTION 'Password incorrect for the desired class';

      END IF;
  END IF;

END;
$$ LANGUAGE plpgsql;

COMMIT;