/**
 * studentControlPanel.js - LearnSQL
 *
 * Michael Torres
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the functions for student control panel
 */


 
const ldb = require('../db/ldb.js');
const logger = require('../logs/winston.js');



/**
 * This function gets all the classes regestered to a student and relevent class
 *  information.
 *
 * @return the classes the user is in and relevent class information
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
				reject({
					message: 'Could query the classes'
				});
				return;
			});
	});
}



module.exports = {
	getClasses,
};
