/**
 * schemaControlPanel.js - LearnSQL
 *
 * Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the functions related to the functionality of tables for a
 *  user.
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
function getObjects(req, res) {
  return new Promise((resolve, reject) => {
    // if user requesting to see table is not owner, test if requesting user is
    // teacher of class
    if (!req.body.username === req.user.username) {
      ldb.any('SELECT Username '
              + 'FROM LearnSQL.Attends '
              + 'WHERE ClassID = $1 AND isTeacher = true',
      [req.body.class])
        .then((result) => {
        // check if each teacher returned is the user requesting to see
          let isTeacher = false;
          result.forEach((element) => {
            if (element === req.body.username) {
              isTeacher = true;
            }
          });
          if (isTeacher === false) {
            throw new Error('User Not Authorized');
          }
        })
        .catch((error) => {
          // if normal error don't log it and send our appropriate response
          if (error === 'User Not Authorized') {
            reject(error);
          } else {
            logger.error(`getObjects: \n${error}`);
            reject(new Error('Server Error: Could query the tables'));
          }
        });
    }
    /**
     * User is either teacher of class or owner of tables at this point
     * Get all tables/views from ClassDB function "StudentTables" where
     * username matches give username
     */
    const db = dbCreator(req.body.class);
    db.any('SELECT Name, Type '
           + 'FROM ClassDB.MajorUserObjects '
           + 'WHERE username = $1 AND schemaname = $1',
    [req.body.username])
      .then((result) => {
        db.$pool.end();// closes the connection to the database. IMPORTANT!!
        resolve();
        return res.status(200).json(result);
      })
      .catch((error) => {
        logger.error(`getObjects: \n${error}`);
        reject(new Error('Server Error: Could query the tables'));
      });
  });
}


/**
 * This function returns a table when given a tableName and the schema qualifier
 *  Schema qualifier is typically the username of the user who created table
 *
 * @param {string} name The name of the object
 * @param {string} schema The schema the table is located in. Normally is the
 *                         username of the user who owns table
 * @param {string} classID The classID of the class the table is in
 * @return a table when given a tableName.
 */
function getObjectDetails(req, res) {
  return new Promise((resolve, reject) => {
    const db = dbCreator(req.body.classID);

    if (req.body.objectType === 'TABLE') {
    // Select all from given table. Sending multiple queries to get multiple
    //  results with pg_promise multi
    db.multi('SELECT Username, SchemaName, TableName, HasIndexes, HasTriggers '
            +'HasRules, Attributes FROM ClassDB.getTableDetails($1,$2); '
            +'SELECT * FROM $1~.$2~', 
      [req.body.schema, req.body.objectName])
      .then((result) => {
      db.$pool.end();// closes the connection to the database. IMPORTANT!!
      resolve();
      console.log(result[0]);
      console.log(result[1]);
      console.log(result[0] + result[1]);
      console.log({ details : result[0], result: result[1] });
      
      return res.status(200).json({ details : result[0], result: result[1] });
      })
      .catch((error) => {
      logger.error(`getTableDetails: \n${error}`);
      reject(new Error('Server Error: Could not get table details'));
      });
    } 
    else if (req.body.type === 'VIEW') { 

    }
    else if (req.body.type === 'FUNCTION') {

    }
    else if (req.body.type === 'TRIGGER') {

    }
    else { 
      
    }
  });
}

module.exports = {
  getObjects,
  getObjectDetails,
};
