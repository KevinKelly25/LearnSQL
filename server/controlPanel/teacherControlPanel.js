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
					logger.error('addStudent: \n' + error);
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
					logger.error('dropStudent: \n' + error);
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
 * @param {string} className the classname the student will be added to
 * @return unformatted student activity from a ClassDB database or an error response
 */
function getStudents(req, res) {
	return new Promise((resolve, reject) => {		
		ldb.one('SELECT C.ClassID ' +
						'FROM Attends AS A INNER JOIN Class AS C ON A.ClassID = C.ClassID '+
						'WHERE Username = $1 AND ClassName = $2',
						[req.user.username, req.body.className])
			.then((result) => {
				var db = dbCreator(result.classid);
				db.any('SELECT * FROM ClassDB.StudentActivitySummary')
				.then((result) => {
					resolve();
					db.$pool.end();//closes the connection to the database. IMPORTANT!!
					return res.status(200).json(result);
				})
				.catch((error)=> {
					logger.error('getStudents: \n' + error);
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
 * This function creates a class database using a ClassDB template Database. It
 *  also addes the class to the attends and class table of the learnsql database.
 *  The access parameters for the database also is restored since they are not
 *  copied over in the creation of the database using the template.
 *
 * @param {string} name the name of the class to be added
 * @param {string} section the section of the class
 * @param {string} times time the class is supposed to meet
 * @param {string} days the days that the class is supposed to meet
 * @param {string} startDate the date of the first class
 * @param {string} endDate the last day of class
 * @param {string} password the join password students need to join class
 * @return http response if class was added or reject promise if error
 */
function createClass(req, res) {
	return handleErrors(req)
	.then(() => {
		var classid = req.body.name + '_' + uniqid(); //guarantee uniqueness
		//check to make sure that there is none conflicting ClassName for that user
		ldb.task( t => {
			return t.oneOrNone('SELECT Username, C.ClassID ' +
							 					 'FROM Attends AS A INNER JOIN Class AS C ' +
												 'ON A.ClassID = C.ClassID ' +
												 'WHERE Username = $1 AND ClassName = $2 AND ' +
												 +	'isTeacher = true',
												 [req.user.username, req.body.name])
			.then((result) => {
				if (result) {
					throw 'Classname Already Exists';
				} else {
					return t.none('CREATE DATABASE $1~ WITH TEMPLATE classdb_template ' +
												' OWNER classdb', classid)
				}
			})
			.then(() => {
				return t.none('INSERT INTO class_t(Classid, ClassName, Section, Times, ' +
											'Days, StartDate, EndDate, Password) ' +
											'VALUES(${id}, ${name}, ${section}, ${times}, ${days}, ' +
											'${startDate}, ${endDate}, ${password} ) '
											, {
												id: classid,
												name: req.body.name,
												section: req.body.section,
												times: req.body.times,
												days: req.body.days,
												startDate: req.body.startDate,
												endDate: req.body.endDate,
												password: req.body.password
											})
			}).
			then(() => {
				return t.none('INSERT INTO attends(username, classid, isteacher) ' +
											'VALUES(${name}, ${class}, ${isTeacher})'
											, {
												name: req.user.username,
												class: classid,
												isTeacher: true
											});
			})
		})
		.then(events => {
			//Readd user access privileges on ClassDB instance
			var db = dbCreator(classid);
			db.any('SELECT reAddUserAccess()')
			.then((result) => {
				db.$pool.end();//closes the connection to the database. IMPORTANT!!
				return res.status(200).json('Class Database Created Successfully');
			})
			.catch((error) => {
				logger.error('reAddUserAccess: \n' + error);
				return res.status(500).json({status: 'Database Privleges could not be added'});
			})
		})
		.catch(error => {			
			if (error == 'Classname Already Exists') {
				res.status(500).json({status: error});
			}
			else {
				logger.error('create Class: \n' + error);
				res.status(500).json({status: 'Database could not be created'});
			}
		});
	})
}


/**
 * This function drops a class database as well as removes it from the attends
 *  and class table from the learnsql database
 *
 * @param {string} name the name of the database
 * @return http response on whether the class was successfully dropped
 */
function dropClass(req, res) {
	return new Promise((resolve, reject) => {
		ldb.task(t => {
			 return t.one('SELECT C.ClassID ' +
										'FROM Attends AS A INNER JOIN Class AS C ' +
										'ON A.ClassID = C.ClassID ' +
										'WHERE Username = $1 AND ClassName = $2 AND isTeacher = True',
										 [req.user.username, req.body.name])
			.then((result) => {
				req.body.classid = result.classid;
			  return t.none('DROP DATABASE $1~ ', result.classid)
			})
			.then(() => {
				return t.none('DELETE FROM attends WHERE classid = $1', req.body.classid)
			})
			.then(() => {
				return t.none('DELETE FROM class WHERE classid = $1', req.body.classid)
			})
			.then(() => {
				resolve();
				return res.status(200).json('Class Database Dropped Successfully');
			})
			.catch(error => {
				reject({
					message: 'Database could not be Deleted'
				});
				logger.error('Drop Class: \n' + error);
			});
		});
	})
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
					message: 'Could not query the classes'
				});
				return;
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
		ldb.any('SELECT Attends.ClassID, ClassName, Section, Times, Days, ' +
						'StartDate, EndDate, StudentCount ' +
						'FROM Attends INNER JOIN Class ON Attends.ClassID = Class.ClassID '+
						'WHERE ClassName = $1 AND Username = $2 AND isTeacher = true', 
						[req.body.className, req.user.username])
			.then((result) => {
				resolve();
				return res.status(200).json(result);
			})
			.catch((error) => {//goes here if you can't find the class
				logger.error('getClass: \n' + error);
				reject({
					message: 'Could not query the classes'
				});
				return;
			});
	});
}



/**
 * handles errors, for now only checks the length of the password
 * Also, set to a low number for testing purposes.
 * 
 * @param {string} password a given password string
 * @returns resolve or reject promise whether conditions were met
 */
function handleErrors(req) {
  // TODO: fix length requirements
  return new Promise((resolve, reject) => {
  if (req.body.password.length < 1) {
      reject({
        message: 'Password must be longer than 6 characters'
      });
    } else {
      resolve();
    }
  });
}



module.exports = {
  addStudent,
  dropStudent,
  getStudents,
	getClasses,
	createClass,
	dropClass,
	getClassInfo
};
