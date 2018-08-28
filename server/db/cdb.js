/**
 * cdb.js - LearnSQL
 *
 * Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the functions for dynamically creating connections to
 *  ClassDB databases
 */

// Loading and initializing the library:
const pgp = require('pg-promise')({
    // Initialization Options
});

/*
 * Exporting the database object for shared use
 *
 * @param {string} query the name of the database
 */
module.exports = function (query) {
	const connectionString = 'postgresql://postgres:password@localhost:5432/'
							 + query;
	return db = pgp(connectionString);
};
