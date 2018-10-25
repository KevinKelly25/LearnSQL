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
                ) 
    THEN
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
                ) 
    AS

$$

BEGIN
  -- Check if the user is enrolled in at least one class
  IF NOT EXISTS (
                  --RETURN QUERY 

                  SELECT ClassName, Section, Times, Days, StartDate,
                         EndDate, StudentCount 
                  FROM LearnSQL.Attends INNER JOIN LearnSQL.Class 
                  ON LearnSQL.Attends.ClassID = LearnSQL.Class.ClassID 
                  WHERE LearnSQL.Attends.Username = studentName 
                  AND Attends.isTeacher = false
                )
    THEN
    RAISE EXCEPTION 'User is not enrolled in any classes';
  END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION
  LearnSQL.addStudent(
                        userName        LearnSQL.Attends.userName%Type, 
                        userFullName    LearnSQL.UserData_t.fullName%Type,
                        userPassword    LearnSQL.UserData_t.password%Type,
                        classID         LearnSQL.Attends.classID%Type,
                        classPassword   LearnSQL.Class_t.password%Type
                                 
                     )
  RETURNS VOID AS

$$
DECLARE

  storedPassword LearnSQL.Class_t.password%Type;

BEGIN

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

  -- Check if the given password matches the stored password
  -- Allows for users to join classes for which no password is set
  
  SELECT password
  INTO storedPassword
  FROM LearnSQL.Class
  WHERE Class.classID = $4;

  IF storedPassword = $5 THEN

    -- Add the student to the class
    INSERT INTO LearnSQL.Attends VALUES($4, $1, 'false');

    -- Create the user under the ClassDB student role using a cross-
    -- database query
    SELECT *
    FROM dblink('user=' || $1 || 'password=' || $3 || 'dbname=classdb_template', 
                'SELECT ClassDB.createStudent(' || $1 || ',' || $2 || ')' )
    AS throwAway(blank VARCHAR(30)); -- Unused return variable for `dblink`

  ELSE

    RAISE EXCEPTION 'Password incorrect for the desired class';

  END IF;

END;
$$ LANGUAGE plpgsql;

COMMIT;