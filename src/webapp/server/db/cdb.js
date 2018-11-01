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
 * @param {string} classid The name of the database
 */
// TODO: Find better way to do this
/* eslint-disable */
module.exports = function (classid) {
  const connectionString = `postgresql://${process.env.DB_USER}`
                         + `:${process.env.DB_PASSWORD}`
                         + `@localhost:5432/${classid}`;
  return db = pgp(connectionString);
};
