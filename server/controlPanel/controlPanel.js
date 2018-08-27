/**
 * controlPanel.js - LearnSQL
 *
 * Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the functions for admin control panel
 */



const ldb = require('../db/ldb.js');
var uniqid = require('uniqid');
const logger = require('../logs/winston.js');
const dbCreator = require('../db/cdb.js');

// TODO: Create class and drop class should be in teacher.js/instructor controlPanel


/**
 * This function creates a class database using a ClassDB template Database. It
 *  also addes the class to the attends and class table of the learnsql database.
 *  The access parameters for the database also is restored since they are not
 *  copied over in the creation of the database using the template.
 *
 * @param {string} name the name of the class.
 * @param {string} password the password the students will use to enter class
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
							 					 'WHERE Username = $1 AND ClassName = $2',
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
				return t.none('INSERT INTO class(classid, classname, password) ' +
											' VALUES(${id}, ${name}, ${password}) '
											, {
												id: classid,
												name: req.body.name,
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
 */
function dropClass(req, res) {
	return handleErrors(req)
	.then(() => {
		ldb.task(t => {
			 return t.one('SELECT C.ClassID ' +
										'FROM Attends AS A INNER JOIN Class AS C ' +
										'ON A.ClassID = C.ClassID ' +
										'WHERE Username = $1 AND ClassName = $2',
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
				return res.status(200).json('Class Database Dropped Successfully');
			})
			.catch(error => {
				logger.error('Drop Class: \n' + error);
				res.status(500).json({status: 'Database could not be Deleted'});
			});
		});
	})
}

/**
 * handles errors, for now only checks the length of the password
 * Also, set to a low number for testing purposes.
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
  createClass,
	dropClass
};
