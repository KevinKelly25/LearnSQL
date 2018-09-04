/**
 * controlPanel.js - LearnSQL
 *
 * Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the functions for admin control panel
 */


const ldb = require('../db/ldb.js');
const dbCreator = require('../db/cdb.js');
const logger = require('../logs/winston.js');

/**
 * This function retrieves all the tables that the given user has in a specific
 *  ClassDB Database. The calling user is checked to see if is either the user
 *  who's tables are being called or one of the teachers of that class. If the
 *  user is authorized, the user is returned a list of all tables.
 *
 * @param {string} username The username of the owner of the tables
 * @param {string} classID The classID of the class the tables are in
 * @return A http response with attached object that contains all the tables the
 *          user has or error details
 */
function getTables(req, res) {
	return new Promise((resolve, reject) => {
    //if user requesting to see table is not owner, test if requesting user is 
    // teacher of class
    if (!req.body.username == req.user.username) {
      ldb.any('SELECT Username ' +
              'FROM Attends ' +
              'WHERE ClassID = $1 AND isTeacher = true', 
              [req.body.class])
      .then((result) => {
        //check if each teacher returned is the user requesting to see
        var isTeacher = false;
        result.forEach(element => {
          if (element == req.body.username) {
            isTeacher = true;
          }
        })
        if (isTeacher == false) {
          throw 'User Not Authorized';
        }
      })
      .catch((error) => {
        //if normal error don't log it and send our appropriate response
        if (error == 'User Not Authorized') {
          reject(error);
          return;
        } else {
          logger.error('getTables: \n' + error);
          reject('Server Error: Could query the tables');
          return;
        }
      });
    }
    /**
     * User is either teacher of class or owner of tables at this point
     * Get all tables/views from ClassDB function "StudentTables" where 
     * username matches give username
     */
    var db = dbCreator(req.body.class);
    db.any('SELECT * ' +
           'FROM ClassDB.StudentTable ' +
           'WHERE username = $1',
           [req.body.username]
          )
    .then((result) => {
      db.$pool.end();//closes the connection to the database. IMPORTANT!!
      resolve();
      return res.status(200).json(result);
    })
    .catch((error) => {   
      logger.error('getTables: \n' + error);
      reject('Server Error: Could query the tables');
      return;
    })
  })
}



/**
 * This function returns a table when given a tableName and the schema qualifier
 *  Schema qualifier is typically the username of the user who created table
 *  
 * @param {string} name the name of the table 
 * @param {string} schema The schema the table is located in. Normally is the 
 *                         username of the user who owns table
 * @param {string} classID The classID of the class the table is in
 * @return a table when given a tableName.
 */
function getTable(req, res) {
	return new Promise((resolve, reject) => {
    var db = dbCreator(req.body.classID);
    //select all from given table. ~ is used for SQL names in pg-promise. 
    //$1 is the schema qualifier and $2 is the name of the table
    db.any('SELECT * ' +
           'FROM $1~.$2~ ',
           [req.body.schema, req.body.name]
          )
    .then((result) => {
      db.$pool.end();//closes the connection to the database. IMPORTANT!!
      resolve();
      return res.status(200).json(result);
    })
    .catch((error) => {
      logger.error('getTable: \n' + error);
      reject('Server Error: Could not query the table');
      return;
    })
  })
}

module.exports = {
  getTables,
  getTable
};