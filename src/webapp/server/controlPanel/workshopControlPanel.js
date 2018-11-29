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
    console.log(JSON.stringify(req.body));
    console.log("Req.body.classid: " + req.body.classID);
    const db = dbCreator(req.body.classID);
    console.log("userQuery: " + req.body.userQuery);

    db.any(req.body.userQuery)
    .then((result) => {
      console.log("Result: " + result);
      resolve();
      db.$pool.end();// Closes the connection to the database
      return res.status(200).json(result);
    })
    .catch((error) => {
      logger.error(`sendQuery: \n${error}`);
      reject(new Error('sendQuery failed'));
    });

  });
}

module.exports = {
  getClasses,
  sendQuery,
};
