// Loading and initializing the library:
const pgp = require('pg-promise')({
    // Initialization Options
});

// Exporting the database object for shared use:
module.exports = function (query) {
	const connectionString = 'postgresql://postgres:password@localhost:5432/'
							 + query.classid;
	return db = pgp(connectionString);
};
