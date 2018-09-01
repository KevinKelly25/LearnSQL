/**
 * controlPanel.js - LearnSQL
 *
 * Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the functions for admin control panel
 */


const ldb = require('../db/ldb.js');
const dbCreator = require('../db/cdb.js');
const logger = require('../logs/winston.js');
const uniqid = require('uniqid');



/**
 * This function gets student information from a ClassDB database. Using the
 *  given classname and the user's username a ClassID is derived; the ClassID is
 *  also the ClassDB database name. Using the ClassID a connection is made to the
 *  database and a database object is returned. This db object then returns all
 *  columns of the StudentActivitySummary which is a view inside of ClassDB.
 *  See https://github.com/DASSL/ClassDB/wiki/Frequent-User-Views for more
 *  information on how ClassDB maintains the student activity
 *
 * @param {string} classname the classname the student will be added to
 * @return unformatted student activity from a ClassDB database or an error response
 */
function getStudents(req, res) {
	return new Promise((resolve, reject) => {
		ldb.one('SELECT C.ClassID ' +
						'FROM Attends AS A INNER JOIN Class AS C ON A.ClassID = C.ClassID '+
						'WHERE Username = $1 AND ClassName = $2',
						[req.user.username, req.body.classname])
			.then((result) => {
				var db = dbCreator(result.classid);
				db.any('SELECT * FROM ClassDB.StudentActivitySummary')
				.then((result) => {
					resolve();
					db.$pool.end();//closes the connection to the database. IMPORTANT!!
					return res.status(200).json(result);
				})
				.catch((error)=> {
					reject({
						message: 'StudentActivitySummary not working'
					});
					return;
				});
			})
			.catch((error) => {//goes here if you can't find the class
				logger.error('getStudents: \n' + error);
				reject({
					message: 'Could not find the class'
				});
				return;
			});
	});
}



/**
 * This function gets all the classes regestered to teacher and relevent class
 *  information.
 *
 * @return the classes the user is in and relevent class information
 */
function getClasses(req, res) {
	return new Promise((resolve, reject) => {
		ldb.any('SELECT ClassName, Section, Times, Days, StartDate, ' +
						'EndDate, StudentCount ' +
						'FROM Attends INNER JOIN Class ON Attends.ClassID = Class.ClassID '+
						'WHERE Username = $1 AND isTeacher = true', [req.user.username])
			.then((result) => {
				resolve();
				return res.status(200).json(result);
			})
			.catch((error) => {//goes here if you can't find the class
				logger.error('getClasses: \n' + error);
				reject({
					message: 'Could query the classes'
				});
				return;
			});
	});
}



module.exports = {
  getStudents,
	getClasses,
};
