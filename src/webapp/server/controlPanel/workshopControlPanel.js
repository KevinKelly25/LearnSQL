/**
 * workshopControlPanel.js - LearnSQL
 *
 * Michael Torres
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the function for getting classes for the workshop
 */


const ldb = require('../db/ldb.js');
const logger = require('../logs/winston.js');


/**
 * This function gets all the classes registered to the current user
 *
 * @return The classes the user is in and relevant class information.
 */
function getClasses(req, res) {
  return new Promise((resolve, reject) => {
    ldb.any(
      'SELECT ClassName, Section, Times, Days, StartDate, '
      + 'EndDate '
      + 'FROM LearnSQL.Attends INNER JOIN LearnSQL.Class_t ON Attends.ClassID = Class_t.ClassID '
      + 'WHERE Username = $1', [req.user.username],
    )
      .then((result) => {
        console.log(result);
        resolve();
        return res.status(200).json(result);
      })
      .catch((error) => { // goes here if you can't find the class.
        logger.error(`getClasses: \n${error}`);
        reject(new Error('Could not query the classes'));
      });
  });
}

module.exports = {
  getClasses,
};