/**
 * schemaControlPanel.js - LearnSQL
 *
 * Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the functions related to the functionality of schemas and
 *  associated objects for a user.
 */


const ldb = require('../db/ldb.js');
const dbCreator = require('../db/cdb.js');
const logger = require('../logs/winston.js');

/**
 * This function retrieves all the objects that the given user has in a specific
 *  ClassDB Database. The calling user is checked to see if is either the user
 *  who's objects are being called or one of the teachers of that class. If the
 *  user is authorized, the user is returned a list of all objects. This function
 *  uses a view from ClassDB called majorUserObjects which lists all objects
 *  in a database, besides default postgres objects
 *
 * @param {string} username The username of the owner of the objects
 * @param {string} classID The classID of the class the object are in
 * @return A http response with attached object that contains all the tables the
 *          user has or error details
 */
function getObjects(req, res) {
  return new Promise((resolve, reject) => {
    // if user requesting to see object is not owner, test if requesting user is
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
     * User is either teacher of class or owner of objects at this point
     * Get all objects from ClassDB view "MajorUserObjects" where
     * username matches give username and schema matches username. This should
     * always show user's private schema since learnSQL doesn't allow custom
     * schema names
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
 * This function returns object details when given the object's name and the
 *  schema the object is in.
 *
 * @param {string} name The name of the object
 * @param {string} schema The schema the object is located in.
 * @param {string} classID The classID of the class the object is in
 * @return object details
 */
function getObjectDetails(req, res) {
  return new Promise((resolve, reject) => {
    const db = dbCreator(req.body.classID);

    if (req.body.objectType === 'TABLE') {
      // Select all from given table. Sending multiple queries to get multiple
      //  results with pg_promise multi
      db.multi('SELECT TableName, HasIndexes, HasTriggers, HasRules, Attributes '
             + 'FROM ClassDB.getTableDetails($1,$2); '
             + 'SELECT * FROM $1~.$2~',
      [req.body.schema, req.body.objectName])
        .then((result) => {
          db.$pool.end();// closes the connection to the database. IMPORTANT!!
          resolve();
          return res.status(200).json({ details: result[0], result: result[1] });
        })
        .catch((error) => {
          logger.error(`getTableDetails: \n${error}`);
          reject(new Error('Server Error: Could not get table details'));
        });
    } else if (req.body.objectType === 'VIEW') {
      // Select all from given view. Sending multiple queries to get multiple
      //  results with pg_promise multi
      db.multi('SELECT ViewName, definition '
             + 'FROM ClassDB.getViewDetails($1,$2); '
             + 'SELECT * FROM $1~.$2~',
      [req.body.schema, req.body.objectName])
        .then((result) => {
          db.$pool.end();// closes the connection to the database. IMPORTANT!!
          resolve();
          return res.status(200).json({ details: result[0], result: result[1] });
        })
        .catch((error) => {
          logger.error(`getViewDetails: \n${error}`);
          reject(new Error('Server Error: Could not get view details'));
        });
    } else if (req.body.objectType === 'FUNCTION') {
      db.any('SELECT FunctionName, NumberOfArguments, ReturnType, '
           + 'EstimatedReturnRows, isAggregate, isWindowFunction, '
           + 'isSecurityDefiner, returnsResultSet, ArgumentTypes, SourceCode '
           + 'FROM ClassDB.getFunctionDetails($1,$2); ',
      [req.body.schema, req.body.objectName])
        .then((result) => {
          db.$pool.end();// closes the connection to the database. IMPORTANT!!
          resolve();
          return res.status(200).json(result);
        })
        .catch((error) => {
          logger.error(`getFunctionDetails: \n${error}`);
          reject(new Error('Server Error: Could not get view details'));
        });
    } else if (req.body.objectType === 'TRIGGER') {
      db.any('SELECT TriggerName, onTable, onFunction '
           + 'FROM ClassDB.getTriggerDetails($1,$2); ',
      [req.body.schema, req.body.objectName])
        .then((result) => {
          db.$pool.end();// closes the connection to the database. IMPORTANT!!
          resolve();
          return res.status(200).json(result);
        })
        .catch((error) => {
          logger.error(`getTriggerDetails: \n${error}`);
          reject(new Error('Server Error: Could not get view details'));
        });
    } else {
      db.any('SELECT indexName, onTable, NumberOfColumns, isUnique, '
           + 'isPrimaryKey, indexDefinition '
           + 'FROM ClassDB.getIndexDetails($1,$2); ',
      [req.body.schema, req.body.objectName])
        .then((result) => {
          db.$pool.end();// closes the connection to the database. IMPORTANT!!
          resolve();
          return res.status(200).json(result);
        })
        .catch((error) => {
          logger.error(`getIndexDetails: \n${error}`);
          reject(new Error('Server Error: Could not get view details'));
        });
    }
  });
}

module.exports = {
  getObjects,
  getObjectDetails,
};
