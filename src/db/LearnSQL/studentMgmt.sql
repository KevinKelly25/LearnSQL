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
                  RETURN QUERY SELECT ClassName, Section, Times, Days, StartDate,
                  EndDate, StudentCount 
                  FROM Attends INNER JOIN Class ON Attends.ClassID = Class.ClassID 
                  WHERE Username = studentName AND isTeacher = false
                )
    THEN
    RAISE EXCEPTION 'User is not enrolled in any classes';
  END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION
  LearnSQL.addStudent(
                        userName      Attends.userName%Type, 
                        classID       Attends.classID%Type,
                        password      Class_t.password%Type,
                        userFullName  LearnSQL.UserData_t.fullName%Type         
                     )
  RETURNS VOID AS

$$
DECLARE

  storedPassword Class_t.password%Type;

BEGIN

  -- Check if the student is already a member of the class
  IF EXISTS (
              SELECT 1
              FROM Attends
              WHERE userName = $2
              AND classID = $1
            ) 
    THEN
    RAISE EXCEPTION 'Student is already a member of the specified class';

  END IF;

  -- Check if the given password matches the stored password
  -- Allows for users to join classes for which no password is set
  IF EXISTS (
              SELECT password
              INTO storedPassword
              FROM Class
              WHERE classID = $2
            ) 
    THEN

    IF storedPassword = $3 THEN

      -- Add the student to the class
      INSERT INTO Attends VALUES($2, $1, 'false');

      -- Create the user under the ClassDB student role using a cross-
      -- database query
      SELECT *
      FROM dblink('dbname = ClassDB', 'SELECT ClassDB.createStudent('|| $1 ||','|| $4')')

    ELSE

      RAISE EXCEPTION 'Password incorrect for the desired class';

    END IF

  END IF;

END;
$$ LANGUAGE plpgsql;


COMMIT;