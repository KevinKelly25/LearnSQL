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
const dbCreator = require('../db/cdb.js');


/**
 * This function gets all the classes registered to a student and relevant class
 *  information.
 *
 * @return the classes the user is in and relevant class information
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
 * This function adds a student to a ClassDB database. Student is checked to see
 *  if they are already in the class. Then the user is then added to the class
 *  via the attends table. Using the ClassID a database object based on the
 *  connection to the ClassDB database is made. This db object then uses the
 *  given username and fullname to create a student in the ClassDB database.
 *  To do this a built in classdb function 'createStudent' is used.
 *  See https://github.com/DASSL/ClassDB/wiki/Adding-Users for more information
 *  on how ClassDB adds students
 *
 * @param {string} password the password used in order to join class
 * @param {string} classID the class id of the class the student will be added to
 * @return http response on if the student was successfully added
 */
function addStudent(req, res) 
{
  return new Promise((resolve, reject) => 
  {
    // TODO: Get instuctor name instead of hardcoding
    //       Accept all date formats
    ldb.oneOrNone('SELECT LearnSQL.getClassID(\'teacher\', $1, $2, $3)',
                  [req.body.className, req.body.classSection, req.body.startDate])
      .then((result) => 
      {
        var classID = 0;
        classID = result.getclassid;
        ldb.any('SELECT LearnSQL.joinClass($1, $2, $3, $4, $5)',
                      [req.user.username, classID, req.body.classPassword, 
                       process.env.DB_USER, process.env.DB_PASSWORD])
        .then((result_joinClass) => 
        {
          resolve();
          return res.status(200).json('Student enrolled successfully');
        })
        .catch((error_joinClass) =>
        {
          // TODO: Test for SQLSTATE or error code instead of error string
          console.log(error_joinClass);
          if(error_joinClass == 'error: Student is already a member of the specified class')
          {
            reject('You are already a member of the specified class');
          }
          else if (error_joinClass == 'error: Password incorrect for the desired class')
          {
            reject('Password incorrect for the desired class');
          }
          else
          {
            reject('Failed to enroll into the desired class');
          }
                
        }); 
      })
      .catch((error) => 
      {
        reject('Class does not exist');
      });
    });
}


module.exports = {
  getClasses,
  addStudent,
};