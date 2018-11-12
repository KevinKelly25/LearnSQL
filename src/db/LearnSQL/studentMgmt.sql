-- studentMgmt.sql - LearnSQL

-- Christopher Innaco
-- Web Applications and Databases for Education (WADE)

-- This file creates the functions involved with student enrollment in classes

START TRANSACTION;

-- Make sure the current user has sufficient privilege to run this script.
--  Privilege required: SUPERUSER

DO
$$
BEGIN
  IF NOT EXISTS (
                  SELECT 1 
                  FROM pg_catalog.pg_roles
                  WHERE rolname = CURRENT_USER 
                  AND rolsuper = TRUE
                ) 
  THEN
    RAISE EXCEPTION 'Insufficient privileges: User must hold superuser '
                    'permissions to execute this script';
  END IF;
END
$$;

--Suppress NOTICEs for this script only, this will not apply to functions
-- defined within. This hides unimportant, and possibly confusing messages.
SET LOCAL client_min_messages TO WARNING;


--  Function returns a table listing the user's currently
--   enrolled classes. When the `isTeacher` parameter is left blank or FALSE is
--   specified, a table containing the classes where the user is a student is 
--   returned. If TRUE is specified, classes where the user is a teacher are 
--   listed. Returns an error if the user is not a member of any class or if the 
--   `isTeacher` is not applicable to the user based on assigned roles.
CREATE OR REPLACE FUNCTION LearnSQL.getClasses(
  userName  LearnSQL.UserData_t.UserName%Type,
  isTeacher BOOLEAN DEFAULT FALSE)
RETURNS TABLE (
                ClassName     LearnSQL.Class_t.ClassName%Type,
                Section       LearnSQL.Class_t.Section%Type,
                Times         LearnSQL.Class_t.Times%Type,
                Days          LearnSQL.Class_t.Days%Type,
                StartDate     LearnSQL.Class_t.StartDate%Type,
                EndDate       LearnSQL.Class_t.EndDate%Type,
                classID       LearnSQL.Class_t.classID%Type,
                StudentCount  LearnSQL.Class.StudentCount%Type
              ) 
AS
$$
BEGIN
  IF NOT EXISTS (
                  SELECT 1
                  FROM LearnSQL.Attends
                  WHERE Attends.userName = $1
                )
  THEN  
    RAISE EXCEPTION 'User is not enrolled or teaching any classes';     
  END IF;

  IF $2 IS TRUE
  THEN
    -- Check if the user is a teacher
    IF NOT EXISTS (
                    SELECT 1
                    FROM LearnSQL.UserData_t
                    WHERE UserData_t.userName = $1
                    AND UserData_t.isTeacher = TRUE
                  )
    THEN
      RAISE EXCEPTION 'User is not a teacher';
    END IF;

    -- Return enrolled classes where the user is a teacher
    RETURN QUERY    
    SELECT Class.ClassName, 
           Class.Section, 
           Class.Times, 
           Class.Days, 
           Class.StartDate,
           Class.EndDate,
           Class.classID, 
           Class.StudentCount 
    FROM LearnSQL.Attends INNER JOIN LearnSQL.Class  
    ON Attends.ClassID = Class.ClassID  
    WHERE Attends.Username = $1
    AND Attends.isTeacher = TRUE;

  ELSE
  -- Check if the user is a student
    IF NOT EXISTS (
                    SELECT 1
                    FROM LearnSQL.Attends
                    WHERE Attends.userName = $1
                    AND Attends.isTeacher = FALSE
                  )
    THEN
      RAISE EXCEPTION 'User is not a student';     
    END IF;
  
  -- Return enrolled classes where the user is a student
    RETURN QUERY    
    SELECT Class.ClassName, 
           Class.Section, 
           Class.Times, 
           Class.Days, 
           Class.StartDate,
           Class.EndDate,
           Class.classID, 
           Class.StudentCount 
    FROM LearnSQL.Attends INNER JOIN LearnSQL.Class  
    ON Attends.ClassID = Class.ClassID  
    WHERE Attends.Username = $1
    AND Attends.isTeacher = FALSE;

  END IF;
END;
$$ LANGUAGE plpgsql 
   STABLE;

--Change function's owner and privileges so that only LearnSQl can use it
ALTER FUNCTION 
  LearnSQL.getClasses(userName  LearnSQL.UserData_t.UserName%Type,
                      isTeacher BOOLEAN) 
  OWNER TO LearnSQL;

REVOKE ALL ON FUNCTION 
  LearnSQL.getClasses(userName  LearnSQL.UserData_t.UserName%Type,
                      isTeacher BOOLEAN) 
  FROM PUBLIC;



--  Function which enrolls the desired user to a class using a class password.
--   When supplied with the optional parameter `adminUserName`, the desired 
--   student is added to the class directly with the administrator user. A class 
--   password is not required when using this optional parameter.
CREATE OR REPLACE FUNCTION LearnSQL.joinClass( 
  userName          LearnSQL.Attends.userName%Type,
  classID           LearnSQL.Attends.classID%Type,
  classPassword     LearnSQL.Class_t.password%Type,
  databaseUsername  VARCHAR(63),
  databasePassword  VARCHAR(64),
  adminUserName     LearnSQL.UserData_t.userName%Type 
                    DEFAULT NULL)
RETURNS VOID AS
$$
DECLARE
  storedClassPassword  LearnSQL.Class_t.password%Type;
  isAdmin              BOOLEAN;
  addStudentQuery      TEXT;
  userFullName         TEXT;
BEGIN
  -- If an administrator's username is supplied, check if the user holds that 
  --  role
  IF $6 IS NOT NULL
  THEN
    -- This query borrows its implementation from ClassDB.isMember() to check
    --  if the administrator has the classdb_admin role
    SELECT
    EXISTS (
              SELECT * FROM pg_catalog.pg_roles
              WHERE pg_catalog.pg_has_role(LOWER($6), oid, 'member')
              AND rolname = 'classdb_admin'
           )
    INTO isAdmin;

    IF (isAdmin IS FALSE)
    THEN
      RAISE EXCEPTION 'The user does not have the permissions necessary to 
                        enroll other students';
    END IF;
  END IF;

  -- Check if the student is already a member of the class
  IF EXISTS (
              SELECT 1
              FROM LearnSQL.Attends
              WHERE Attends.userName = $1
              AND Attends.classID = $2
            ) 
  THEN
    RAISE EXCEPTION 'Student is already a member of the specified class';
  END IF;

  SELECT password
  INTO storedClassPassword
  FROM LearnSQL.Class
  WHERE Class.classID = $2;

  -- Check if the given password matches the stored password.
  --  Allows for users to join classes for which no password is set.
  --  Allows administrators to force a student to enroll in a class.
  IF storedClassPassword = LearnSQL.crypt($3, storedClassPassword)  
  OR isAdmin IS TRUE 
  THEN
    -- Add the student to the class
    INSERT INTO LearnSQL.Attends VALUES($2, $1, 'FALSE');

    SELECT fullName
    INTO userFullName
    FROM LearnSQL.UserData_t
    WHERE UserData_t.userName = $1;

    -- Create the user under the ClassDB student role using a cross-
    -- database query
    addStudentQuery = 'SELECT ClassDB.createStudent(
                                                '''|| userName ||''', 
                                                '''|| userFullName ||''')';
    PERFORM *
    FROM LearnSQL.dblink('user='     || $4 || 
                        ' password=' || $5 || 
                        ' dbname='   || $2, addStudentQuery)
    AS throwAway(blank VARCHAR(30)); 
    -- Needed for dblink and the unused return value of this query

  ELSE
    RAISE EXCEPTION 'Password incorrect for the desired class';
  END IF;
END;
$$ LANGUAGE plpgsql;

--Change function's owner and privileges so that only LearnSQl can use it
ALTER FUNCTION 
  LearnSQL.joinClass(userName          LearnSQL.Attends.userName%Type,
                     classID           LearnSQL.Attends.classID%Type,
                     classPassword     LearnSQL.Class_t.password%Type,
                     databaseUsername  VARCHAR(63),
                     databasePassword  VARCHAR(64),
                     adminUserName     LearnSQL.UserData_t.userName%Type) 
  OWNER TO LearnSQL;

REVOKE ALL ON FUNCTION 
  LearnSQL.joinClass(userName          LearnSQL.Attends.userName%Type,
                     classID           LearnSQL.Attends.classID%Type,
                     classPassword     LearnSQL.Class_t.password%Type,
                     databaseUsername  VARCHAR(63),
                     databasePassword  VARCHAR(64),
                     adminUserName     LearnSQL.UserData_t.userName%Type) 
  FROM PUBLIC;

COMMIT;