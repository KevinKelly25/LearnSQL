/**
 * studentControlPanel.js - LearnSQL
 *
 * Christopher Innaco, Kevin Kelly, Michael Torres
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the functions for student control panel
 */


const ldb = require('../db/ldb.js');
const logger = require('../logs/winston.js');


/**
 * This function calls the `LearnSQL.getClasses()` PL/pgSQL function which
 *  returns a list of classes in which the student is registered with additional
 *  relevant class information.
 *
 * @return the classes the user is enrolled and relevant class information
 */
function getClasses(req, res) {
  return new Promise((resolve, reject) => {
    ldb.any('SELECT * FROM LearnSQL.getClasses($1)', [req.user.username])
      .then((result) => {
        resolve();
        return res.status(200).json(result);
      })
      .catch((error) => {
        logger.error(`getClasses: \n${error}`);
        reject(new Error('Server Error: Could not query the classes'));
      });
  });
}


/**
 * This function calls the `LearnSQL.joinClass()` PL/pgSQL function which
 *  enrolls a student into a class when given a classID and classPassword.
 *  Various checks are present to ensure the class exists and the user is
 *  not a current member of the class. If successful, a cross-database query
 *  to the PL/pgSQL function `SELECT ClassDB.createStudent()` is called for
 *  the user and a record is added to the `LearnSQL.Attends` table.
 *  See https://github.com/DASSL/ClassDB/wiki/Adding-Users for more information
 *  on how ClassDB adds students.
 *
 * @param {string} classPassword the password used to enroll into the class
 * @param {string} classID the classID of the class the student will be added to
 * @return http response if the student was successfully added
 */
function addStudent(req, res) {
  return new Promise((resolve, reject) => {
    ldb.func('LearnSQL.joinClass',
      [req.user.username, req.body.classID, req.body.classPassword,
        process.env.DB_USER, process.env.DB_PASSWORD])

      .then(() => {
        resolve();
        return res.status(200).json('Student enrolled successfully');
      })
      .catch((error) => {
        /* eslint-disable prefer-promise-reject-errors */
        if (error.code === '42710') {
          reject('You are already a member of the specified class');
        } else if (error.code === '28P01') {
          reject('Password incorrect for the desired class');
        } else if (error.code === '42704') {
          reject('Class not found');
        } else {
          reject('Failed to enroll into the desired class');
        }
        /* eslint-enable prefer-promise-reject-errors */
      });
  });
}


module.exports = {
  getClasses,
  addStudent,
};
