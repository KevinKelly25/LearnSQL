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


// TODO: add student to learnsql database as well
/**
 * This function adds a student to a ClassDB database. Using the given classname
 *  and the user's username a ClassID is derived; the ClassID is also the ClassDB
 *  database name. Using the ClassID a connection is made to the database and a
 *  database object is returned. This db object then uses the given username and
 *  fullname to create a student in the ClassDB database. To do this a built in
 *  classdb function 'createStudent' is used. See https://github.com/DASSL/ClassDB/wiki/Adding-Users
 *  for more information on how ClassDB adds students
 *
 * @param {string} username the username of the student to be added
 * @param {string} fullname the full name of the student
 * @param {string} classname the classname the student will be added to
 * @return response
 */
function addStudent(req, res) {
	return new Promise((resolve, reject) => {
		ldb.one('SELECT C.ClassID ' +
				'FROM Attends AS A INNER JOIN Class AS C ON A.ClassID = C.ClassID ' +
				'WHERE Username = $1 AND ClassName = $2', [req.user.username, req.body.classname])
				.then((result) => {
					var db = dbCreator(result.classid);
					db.func('ClassDB.createStudent',
						[req.body.username, req.body.fullname])
					.then((result) => {
						resolve();
						db.$pool.end();//closes the connection to the database. IMPORTANT!!
						return res.status(200).json('student added successfully');
					})
					.catch((error)=> {
						reject({
							message: 'Could not create student'
						});
						db.$pool.end();
						return;
					});
				})
				.catch((error) => {//goes here if you can't find the class
					reject({
						message: 'Could not find the class'
					});
					return;
				});
		});
}



// TODO: remove student from learnsql database
/**
 * This function drops a student to a ClassDB database. Using the given classname
 *  and the user's username a ClassID is derived; the ClassID is also the ClassDB
 *  database name. Using the ClassID a connection is made to the database and a
 *  database object is returned. This db object then uses the given username remove
 *  the student in the ClassDB database. This does not remove a student's role
 *  from the postgres server. To remove a student a built in classdb function
 * 'dropStudent' is used. See https://github.com/DASSL/ClassDB/wiki/Removing-Users
 *  for more information on how ClassDB removes students
 *
 * @param {string} username the username of the student to be added
 * @param {string} classname the classname the student will be added to
 * @return response
 */
function dropStudent(req, res) {
	return new Promise((resolve, reject) => {
		ldb.one('SELECT C.ClassID ' +
				'FROM Attends AS A INNER JOIN Class AS C ON A.ClassID = C.ClassID ' +
				'WHERE Username = $1 AND ClassName = $2', [req.user.username, req.body.classname])
				.then((result) => {
					var db = dbCreator(result.classid);
					db.func('ClassDB.dropStudent', [req.body.username, false,
							true, 'drop'])
					.then((result) => {
						resolve();
						db.$pool.end();//closes the connection to the database. IMPORTANT!!
						return res.status(200).json('Student Dropped Successfully');
					})
					.catch((error)=> {
						reject({
							message: 'could not drop student'
						});
						return;
					});
				})
				.catch((error) => {//goes here if you can't find the class
					reject({
						message: 'Could not find the class'
					});
					return;
				});
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
 * @param {string} classname the classname the student will be added to
 * @return unformatted student activity from a ClassDB database or an error response
 */
function getClass(req, res) {
	return new Promise((resolve, reject) => {
		ldb.one('SELECT C.ClassID ' +
				'FROM Attends AS A INNER JOIN Class AS C ON A.ClassID = C.ClassID ' +
				'WHERE Username = $1 AND ClassName = $2', [req.user.username, req.body.classname])
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
					reject({
						message: 'Could not find the class'
					});
					return;
				});
		});
}



module.exports = {
  addStudent,
  dropStudent,
  getClass
};
