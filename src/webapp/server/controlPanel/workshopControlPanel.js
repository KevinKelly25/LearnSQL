/**
 * workshopControlPanel.js - LearnSQL
 *
 * Christopher Innaco, Michael Torres
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the function for getting classes for the workshop
 */

/* eslint-disable arrow-body-style */
/* eslint-disable arrow-parens */

const ldb = require('../db/ldb.js');
const dbCreator = require('../db/cdb.js');
const logger = require('../logs/winston.js');

// eslint-disable-next-line no-var
var lastClassID = 0;

/**
 * For each class the user is enrolled, detailed class information is returned
 *
 * @return The classes the user is in and relevant class information.
 */
function getClasses(req, res) {
  return new Promise((resolve, reject) => {
    ldb.any(
      'SELECT Attends.ClassID, ClassName, Section, Times, Days, StartDate, EndDate, Attends.isTeacher '
    + 'FROM LearnSQL.Attends INNER JOIN LearnSQL.Class_t ON Attends.ClassID = Class_t.ClassID '
    + 'WHERE Attends.username = $1', [req.user.username],
    )
      .then((result) => {
        resolve();
        return res.status(200).json(result);
      })
      .catch((error) => {
        // If class not found
        logger.error(`getClasses: \n${error}`);
        reject(new Error('Could not query the classes'));
      });
  });
}


let db = null;

function changeClassDatabaseConnection(classID) {
  db = null;
  db = dbCreator(classID);
}

/**
 * Runs a user's query on the database which matches the classID provided.
 *
 * @return The results of the query
 */
function sendQuery(req, res) {
  return new Promise((resolve, reject) => {
    if (!(req.body.classID === lastClassID) || db === null) {
      changeClassDatabaseConnection(req.body.classID);
    }
    lastClassID = req.body.classID;
    db.task(t => {
      return t.oneOrNone('SET ROLE $1', [req.user.username])
        .then(() => {
          return t.any(req.body.userQuery);
        });
    })
      .then((resultUserQuery) => {
        resolve();
        return res.status(200).json(resultUserQuery);
      })
      .catch((errorUserQuery) => {
        reject(errorUserQuery.message);
      });
  });
}

/**
 * Closes the connection pool to the class's database.
 *  Called when the user navigates away from the `sandbox.html` page.
 *
 * @return HTTP response code and string signifying if pool was closed
 */
// eslint-disable-next-line no-unused-vars
function closeConnection(req, res) {
  return new Promise((resolve, reject) => {
    // Close the connection pool if open
    if (!db.$pool.ending) {
      db.$pool.end();
      db = null;

      resolve();
      return res.status(200).json('Connection pool closed');
    }
    reject();
    return res.status(500).json('Failed to close connection pool');
  });
}


module.exports = {
  getClasses,
  sendQuery,
  closeConnection,
};
