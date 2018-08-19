/**
 * controlPanel.js - LearnSQL
 *
 * Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the functions for admin control panel
 */



const db = require('../db/ldb.js');
var uniqid = require('uniqid');

/**
 * This funciton creates a class database using a ClassDB template Database
 */
function createClass(req, res) {
	return handleErrors(req)
	.then(() => {
		var classid = req.body.name + '_' + uniqid(); //guarantee uniqueness
		//check to make sure that there is none conflicting ClassName for that user
		db.none('SELECT Username, C.ClassID ' +
						'FROM Attends AS A INNER JOIN Class AS C ON A.ClassID = C.ClassID ' +
						'WHERE Username = $1 AND ClassName = $2', [req.user.username, req.body.name])
						.then(() => {
							db.task(t => {
									return t.none('CREATE DATABASE $1~ WITH TEMPLATE classdb_template OWNER classdb', classid)
											.then(() => {
												return t.none('INSERT INTO class(classid, classname, password) VALUES(${id}, ${name}, ${password}) '
											, {
												id: classid,
												name: req.body.name,
												password: req.body.password
											})
											.then(() => {
												return t.none('INSERT INTO attends(username, classid, isteacher) VALUES(${name}, ${class}, ${isTeacher})'
												, {
													name: req.user.username,
													class: classid,
													isTeacher: true
													});
												});
										});
							})
							.then(events => {
									return res.status(200).json('Class Database Created Successfully');
							})
							.catch(error => {
									res.status(400).json({status: 'Database could not be created'});
							});
						})
						.catch(error => {
						    res.status(400).json({status: 'Class Already Exists With That Name'});
						});
	})
}


/**
 * This funciton creates a class database using a ClassDB template Database
 */
function removeClass(req, res) {
	return handleErrors(req)
	.then(() => {
		db.task(t => {
				return t.one('SELECT C.ClassID ' +
								'FROM Attends AS A INNER JOIN Class AS C ON A.ClassID = C.ClassID ' +
								'WHERE Username = $1 AND ClassName = $2', [req.user.username, req.body.name])
						.then((classid) => {
							console.log(classid);
						  return	t.none('DROP DATABASE $1~ ', classid)
						})
						.then(() => {
							return t.none('DELETE FROM attends WHERE classid = $1', classid)
						})
						.then(() => {
							return t.none('DELETE FROM class WHERE classid = $1', classid)
						});
					});
		})
		.then(events => {
				return res.status(200).json('Class Database Dropped Successfully');
		})
		.catch(error => {
				res.status(400).json({status: 'Database could not be Deleted'});
		});
}

/**
 * handles errors, for now only checks the length of the password
 * Also, set to a low number for testing purposes.
 */
function handleErrors(req) {
	console.log('handleErrors');
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
	removeClass
};
