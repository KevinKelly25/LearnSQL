/**
 * controlPanel.js - LearnSQL
 *
 * Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the functions for admin control panel
 */


const uniqid = require('uniqid');
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
 *  given classname and the user's username a ClassID is derived; the ClassID is
 *  also the ClassDB database name. Using the ClassID a connection is made to the
 *  database and a database object is returned. This db object then returns all
 *  columns of the StudentActivitySummary which is a view inside of ClassDB.
 *  See https://github.com/DASSL/ClassDB/wiki/Frequent-User-Views for more
 *  information on how ClassDB maintains the student activity
 *
 * @param {string} className The classname the student will be added to
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
            db.$pool.end();// closes the connection to the database. IMPORTANT!!
            return res.status(200).json(result2);
          })
          .catch((error) => {
            logger.error(`getStudents: \n${error}`);
            reject(new Error('StudentActivitySummary not working'));
          });
      })
      .catch((error) => { // goes here if you can't find the class
        logger.error(`getStudents: \n${error}`);
        reject(new Error('Could not find the class'));
      });
  });
}


/**
 * This function creates a class database using a ClassDB template Database. It
 *  also adds the class to the attends and class table of the learnsql database.
 *  The access parameters for the database also is restored since they are not
 *  copied over in the creation of the database using the template.
 *
 * @param {string} name The name of the class to be added
 * @param {string} section The section of the class
 * @param {string} times Time the class is supposed to meet
 * @param {string} days The days that the class is supposed to meet
 * @param {string} startDate The date of the first class
 * @param {string} endDate The last day of class
 * @param {string} password The join password students need to join class
 * @return Http response if class was added or reject promise if error
 */
function createClass(req, res) {
  return handleErrors(req)
    .then(() => {
      const classid = `${req.body.name}_${uniqid()}`; // Guarantee uniqueness
      // Check to make sure that there is none conflicting ClassName for that user
      ldb.task(t => t.oneOrNone('SELECT Username, C.ClassID '
                         + 'FROM LearnSQL.Attends AS A INNER JOIN Class AS C '
                         + 'ON A.ClassID = C.ClassID '
                         + 'WHERE Username = $1 AND ClassName = $2 AND '
                         + 'isTeacher = true',
      [req.user.username, req.body.name])
        .then((result) => {
          if (result) {
            throw new Error('Classname Already Exists');
          } else {
            return t.none('CREATE DATABASE $1~ WITH TEMPLATE classdb_template '
                          + ' OWNER classdb', classid);
          }
        })
        .then(() => t.none(
          'INSERT INTO LearnSQL.class_t(Classid, ClassName, Section, Times, '
          + 'Days, StartDate, EndDate, Password) '
          + 'VALUES($1, $2, $3, $4, $5, $6, $7, $8)',
          [
            classid, req.body.name, req.body.section, req.body.times,
            req.body.days, req.body.startDate, req.body.endDate, req.body.password,
          ],
        ))
        .then(() => t.none(
          'INSERT INTO LearnSQL.Attends(username, classid, isteacher) '
          + 'VALUES($1, $2, $3)',
          [req.user.username, classid, true],
        )))
        .then(() => {
          // Readd user access privileges on ClassDB instance
          const db = dbCreator(classid);
          db.any('SELECT reAddUserAccess()')
            .then(() => {
              db.$pool.end();// closes the connection to the database. IMPORTANT!!
              return res.status(200).json('Class Database Created Successfully');
            })
            .catch((error) => {
              logger.error(`reAddUserAccess: \n${error}`);
              return res.status(500).json({ status: 'Database Privleges could not be added' });
            });
        })
        .catch((error) => {
          if (error === 'Classname Already Exists') {
            res.status(500).json({ status: error });
          } else {
            logger.error(`create Class: \n${error}`);
            res.status(500).json({ status: 'Database could not be created' });
          }
        });
    });
}


/**
 * This function drops a class database as well as removes it from the attends
 *  and class table from the learnsql database
 *
 * @param {string} name The name of the database
 * @return Http response on whether the class was successfully dropped
 */
function dropClass(req, res) {
  return new Promise((resolve, reject) => {
    ldb.task(t => t.one(
      'SELECT C.ClassID '
      + 'FROM LearnSQL.Attends AS A INNER JOIN Class AS C '
      + 'ON A.ClassID = C.ClassID '
      + 'WHERE Username = $1 AND ClassName = $2 AND isTeacher = True',
      [req.user.username, req.body.name],
    )
      .then((result) => {
        req.body.classid = result.classid;
        return t.none('DROP DATABASE $1~ ', result.classid);
      })
      .then(() => t.none('DELETE FROM LearnSQl.Attends WHERE classid = $1', req.body.classid))
      .then(() => t.none('DELETE FROM class WHERE classid = $1', req.body.classid))
      .then(() => {
        resolve();
        return res.status(200).json('Class Database Dropped Successfully');
      })
      .catch((error) => {
        reject(new Error('Database could not be Deleted'));
        logger.error(`Drop Class: \n${error}`);
      }));
  });
}


/**
 * This function gets all the classes regestered to teacher and relevent class
 *  information.
 *
 * @return The classes the user is in and relevent class information
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
      .catch((error) => { // goes here if you can't find the class
        logger.error(`getClasses: \n${error}`);
        reject(new Error('Could not query the classes'));
      });
  });
}

/**
 * This function gets all the class information for a class when given a
 *  className
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
      .catch((error) => { // goes here if you can't find the class
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
