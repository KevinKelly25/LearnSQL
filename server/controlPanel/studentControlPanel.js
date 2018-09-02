/**
 * studentControlPanel.js - LearnSQL
 *
 * Michael Torres, Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the functions for student control panel
 */


 
const ldb = require('../db/ldb.js');
const logger = require('../logs/winston.js');
const authHelpers = require('../auth/_helpers');
const dbCreator = require('../db/cdb.js');



/**
 * This function gets all the classes registered to a student and relevant class
 *  information.
 *
 * @return the classes the user is in and relevant class information
 */
function getClasses(req, res) {
	return new Promise((resolve, reject) => {
		ldb.any('SELECT ClassName, Section, Times, Days, StartDate, ' +
						'EndDate, StudentCount ' +
						'FROM Attends INNER JOIN Class ON Attends.ClassID = Class.ClassID '+
						'WHERE Username = $1 AND isTeacher = false', [req.user.username])
			.then((result) => {
				resolve();
				return res.status(200).json(result);
			})
			.catch((error) => {
				logger.error('getClasses: \n' + error);
				reject('Server Error: Could not query the classes');
				return;
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
 * 	See https://github.com/DASSL/ClassDB/wiki/Adding-Users for more information
 *  on how ClassDB adds students
 *
 * @param {string} password the password used in order to join class
 * @param {string} classID the class id of the class the student will be added to
 * @return http response on if the student was successfully added 
 */
function addStudent(req, res) {
	return new Promise((resolve, reject) => {
		ldb.task(t => {
			//If student is already in class there will be a result. Otherwise, there
			// will be no result object
			return t.oneOrNone('SELECT 1 ' +
			                   'FROM Attends ' + 
												 'WHERE Username = $1 AND ClassID = $2',
												 [req.user.username, req.body.classID])
			.then((result) => {
				if (result) {
					throw 'Already Joined The Class';
				} else {
					//Get class join password
					return t.one('SELECT Password ' +
											 'FROM Class ' +
											 'WHERE ClassID = $1',
											 [req.body.classID])
					.then((result) =>{
						//TODO: once hash password used switch to authHelpers.CompareHashed
						if (req.body.password != result.password) {
							throw 'Join Password Incorrect';
						}
					})
				}
			})
			.then(() => {
				//insert student into specified class
				return t.none('INSERT INTO Attends VALUES($1, $2, false)', 
			                 [req.body.classID, req.user.username])
			})
			.then(() => {
				//Create a db object on ClassDB database and add student
				var db = dbCreator(req.body.classID);
					db.func('ClassDB.createStudent',
						[req.user.username, req.user.fullname])
					.then((result) => {
						resolve();
						db.$pool.end();//closes the connection to the database. IMPORTANT!!
						return res.status(200).json('student added successfully');
					})
					.catch((error)=> {
						reject('Server Error: Could not create student');
						db.$pool.end();
						return;
					});
			})						 
		})
		.catch((error) => {
			//if common error send it back to user, otherwise log it and send back
			// server error message to user
			if (error=='Join Password Incorrect'||error=='Already Joined The Class'){
				reject(error);
				return;
			} else {
				logger.error('addStudent: \n' + error);
				reject('Server Error: Could not add you to the class');
				return;
			}
		})
	});
}



module.exports = {
	getClasses,
	addStudent
};
