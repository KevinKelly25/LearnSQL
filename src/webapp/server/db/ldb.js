// Loading and initializing the library:
const pgp = require('pg-promise')({
  // Initialization Options
});

// Preparing the connection details:
const connectionString = `postgresql://${process.env.DB_USER}:`
                       + `${process.env.DB_PASSWORD}`
                       + '@localhost:5432/learnsql';

// Creating a new database instance from the connection details:
const db = pgp(connectionString);

// Exporting the database object for shared use:
module.exports = db;
