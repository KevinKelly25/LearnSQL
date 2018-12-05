/**
 * workshopControlPanel.js - LearnSQL
 *
 * Christopher Innaco, Michael Torres
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the function for getting classes for the workshop
 */


const ldb = require('../db/ldb.js');
const dbCreator = require('../db/cdb.js');
const logger = require('../logs/winston.js');


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

function sendQuery(req, res) {
  return new Promise((resolve, reject) => {
    let db = dbCreator(req.body.classID);

    // Set the current_user to access the user's tables
    db.oneOrNone('SET ROLE $1', [req.user.username])
      .then(() => {
        db.any(req.body.userQuery)
          .then((resultUserQuery) => {
            resolve();

            // Closes the connection to the database
            db.$pool.end();

            // Force garbage collection to prevent multiple database objects for the same connection
            db = null;

            return res.status(200).json(resultUserQuery);
          })

          .catch((errorUserQuery) => {
            reject(errorUserQuery.message);
          });
      })
      .catch((errorRole) => {
        logger.error(`sendQuery Role: \n${errorRole}`);
        reject(new Error('sendQuery failed: Cannot set role'));
      });
  });
}

module.exports = {
  getClasses,
  sendQuery,
};
