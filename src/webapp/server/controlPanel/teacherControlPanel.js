/**
 * controlPanel.js - LearnSQL
 *
 * Kevin Kelly, Michael Torres
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the functions for admin control panel
 */


const ldb = require('../db/ldb.js');
const dbCreator = require('../db/cdb.js');
const logger = require('../logs/winston.js');



/**
 * handles errors, for now only checks the length of the password
 *  Also, set to a low number for testing purposes.
 *
 * @param {string} password A given password string
 * @returns Resolve or reject promise whether conditions were met
 */
function handleErrors(req) {
  // TODO: fix length requirements
  return new Promise((resolve, reject) => {
    if (req.body.password.length < 1) {
      reject(new Error('Password must be longer than 6 characters'));
    } else {
      resolve();
    }
  });
}



/**
 * This function gets student information from a ClassDB database. Using the
 *  given className and the user's username a ClassID is derived; the ClassID is
 *  also the ClassDB database name. Using the ClassID a connection is made to the
 *  database and a database object is returned. This db object then returns all
 *  columns of the StudentActivitySummary which is a view inside of ClassDB.
 *  See https://github.com/DASSL/ClassDB/wiki/Frequent-User-Views for more
 *  information on how ClassDB maintains the student activity
 *
 * @param {string} className The className the student will be added to
 * @return Unformatted student activity from a ClassDB database or an error response
 */
function getStudents(req, res) {
  return new Promise((resolve, reject) => {
    ldb.one('SELECT C.ClassID '
            + 'FROM LearnSQL.Attends AS A INNER JOIN Class AS C ON A.ClassID = C.ClassID '
            + 'WHERE Username = $1 AND ClassName = $2',
    [req.user.username, req.body.className])
      .then((result) => {
        const db = dbCreator(result.classid);
        db.any('SELECT * FROM ClassDB.StudentActivitySummary')
          .then((result2) => {
            resolve();
            db.$pool.end();// Closes the connection to the database. IMPORTANT!!
            return res.status(200).json(result2);
          })
          .catch((error) => {
            logger.error(`getStudents: \n${error}`);
            reject(new Error('StudentActivitySummary not working'));
          });
      })
      .catch((error) => { // Goes here if you can't find the class.
        logger.error(`getStudents: \n${error}`);
        reject(new Error('Could not find the class'));
      });
  });
}


/**
 * This function creates a class database using a ClassDB template Database. It
 *  also adds the class to the attends and class table of the LearnSQL database.
 *  The access parameters for the database also is restored since they are not
 *  copied over in the creation of the database using the template.
 *
 * @param {string} dbUserName The name of the database user.
 * @param {string} dbPassword The database password.
 * @param {string} teacherUserName The teacher's username.
 * @param {string} classPassword The password for the class.
 * @param {string} className The name of the class to be added.
 * @param {string} section The section of the class.
 * @param {string} times Time the class is supposed to meet.
 * @param {string} days The days that the class is supposed to meet.
 * @param {string} startDate The date of the first class.
 * @param {string} endDate The last day of class.
 */
function createClass(req, res) {
  return handleErrors(req)
    .then(() => {
      ldb.func('LearnSQL.createClass',
        [process.env.DB_USER, process.env.DB_PASSWORD, req.user.username, req.body.password,
          req.body.className, req.body.section, req.body.times, req.body.days,
          req.body.startDate, req.body.endDate])
        .then(result => res.status(200).json(result))
        .catch((error) => {
          logger.error(`createClasses: \n${error}`);
          if (error.message === 'Section And Class Name Already Exists!') {
            return res.status(400).json('Section And Class Name Already Exists!');
          }
          if (error.constraint === 'class_t_classname_check'
              || error.code === '23502') {
            return res.status(400).json('Required field is missing!');
          }
          if (error.code === '22007') {
            return res.status(400).json('Required field has incorrect format!');
          }

          return res.status(500).json('error');
        });
    });
}

/**
 * This function drops a class database as well as removes it from the attends
 *  and class table from the LearnSQL database.
 *
 * @param {string} dbUsername The user name of the database user.
 * @param {string} dbPassword The password of the user for the database.
 * @param {string} className The name of the database.
 * @param {string} section The name of the section of the class.
 * @param {date} startDate The start date of the class.
 */
function dropClass(req, res) {
  return new Promise(() => {
    ldb.func('LearnSQL.dropClass',
      [process.env.DB_USER, process.env.DB_PASSWORD, req.user.username,
        req.body.className, req.body.section, req.body.startDate])
      .then(result => res.status(200).json(result))
      .catch((error) => {
        logger.error(`dropClass: \n${error}`);
        res.status(500).json('Server error');
      });
  });
}


/**
 * This function gets all the classes registered to teacher and relevant class
 *  information.
 *
 * @return The classes the user is in and relevant class information.
 */
function getClasses(req, res) {
  return new Promise((resolve, reject) => {
    ldb.any(
      'SELECT ClassName, Section, Times, Days, StartDate, '
      + 'EndDate, StudentCount '
      + 'FROM LearnSQL.Attends INNER JOIN LearnSQL.Class ON Attends.ClassID = Class.ClassID '
      + 'WHERE Username = $1 AND isTeacher = true', [req.user.username],
    )
      .then((result) => {
        resolve();
        return res.status(200).json(result);
      })
      .catch((error) => { // goes here if you can't find the class.
        logger.error(`getClasses: \n${error}`);
        reject(new Error('Could not query the classes'));
      });
  });
}

/**
 * This function gets all the class information for a class when given a
 *  className.
 *
 * @param className
 * @return class information
 */
function getClassInfo(req, res) {
  return new Promise((resolve, reject) => {
    ldb.any(
      'SELECT LearnSQL.Attends.ClassID, ClassName, Section, Times, Days, '
      + 'StartDate, EndDate, StudentCount '
      + 'FROM LearnSQL.Attends INNER JOIN LearnSQL.Class ON Attends.ClassID = Class.ClassID '
      + 'WHERE ClassName = $1 AND Username = $2 AND isTeacher = true',
      [req.body.className, req.user.username],
    )
      .then((result) => {
        resolve();
        return res.status(200).json(result);
      })
      .catch((error) => { // Goes here if you can't find the class.
        logger.error(`getClass: \n${error}`);
        reject(new Error('Could not query the classes'));
      });
  });
}



module.exports = {
  getStudents,
  getClasses,
  createClass,
  dropClass,
  getClassInfo,
};
