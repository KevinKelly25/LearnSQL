CREATE OR REPLACE FUNCTION reAddUserAccess()
   RETURNS VOID AS
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
END;
$$ LANGUAGE plpgsql;
