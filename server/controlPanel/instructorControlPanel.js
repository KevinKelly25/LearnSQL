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

/**
 * This is a test function that demonstrates the way to connect to a classdb
 *  database.
 */
 // TODO: Instead of using db.$pool.end() there might be a better way to store
 //        objects so that a new connection doesnt need to be opened for every
 //        it is very important to chain as many queries into one connection as
 //        as possible and not recreate db object for every query via dbCreator
 //        default timeout for db connection is 30 sec which is why we need to
 //        force close
function selectClass(req, res) {
	return new Promise((resolve, reject) => {
		ldb.one('SELECT C.ClassID ' +
				'FROM Attends AS A INNER JOIN Class AS C ON A.ClassID = C.ClassID ' +
				'WHERE Username = $1 AND ClassName = $2', [req.user.username, req.body.name])
				.then((result) => {
					console.log(result);
					var db = dbCreator(result);
					db.one('SELECT * FROM ClassDB.DDLActivity')
					.then((result) => {
						console.log(result);
						resolve();
						db.$pool.end();//closes the connection to the database. IMPORTANT!!
						return res.status(200).json('Class Database Created Successfully');
					})
					.catch((error)=> {
						reject({
							message: 'query failed'
						});
						console.log(error);
					});
				})
				.catch((error) => {//goes here if you can't find the class
					console.log(error);
				});
		});
}



module.exports = {
  selectClass
};
