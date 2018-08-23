/**
 * teacher.js - LearnSQL
 *
 * Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file sets up the http routes associated with teacher functionality
 */



const express = require('express');
const router = express.Router();

const teacherHelpers = require('../controlPanel/instructorControlPanel.js');
const authHelpers = require('../auth/_helpers');



/**
 * This method adds a student to a ClassDB database. Most functionality is in
 *  `instructorControlPanel.js` addStudent function but is expecting a promise
 *  to be returned
 *
 * @param {string} username the username of the student to be added
 * @param {string} fullname the full name of the student
 * @param {string} classname the classname the student will be added to
 * @return response
 */
router.post('/addStudent', authHelpers.teacherRequired, (req, res, next)  => {
	return teacherHelpers.addStudent(req, res)
	.catch((err) => {
		handleResponse(res, 500, err);
	});
});



/**
 * This method returns class information from a ClassDB database. Most
 *  functionality is in `instructorControlPanel.js` getClass function.
 *  expects a promise to be returned
 *
 * @param {string} classname the classname the student will be added to
 * @return response
 */
router.post('/getClass', authHelpers.teacherRequired, (req, res, next)  => {
	return teacherHelpers.getClass(req, res)
	.catch((err) => {
		handleResponse(res, 500, err);
	});
});



/**
 * This method removes a student from a ClassDB database. Most functionality is
 *  contained in `instructorControlPanel.js` dropStudent function. Expects a
 *  promise to be returned
 *
 * @param {string} username the username of the student to be added
 * @param {string} classname the classname the student will be added to
 * @return response
 */
router.post('/dropStudent', authHelpers.teacherRequired, (req, res, next)  => {
	return teacherHelpers.dropStudent(req, res)
	.catch((err) => {
		handleResponse(res, 500, err);
	});
});



/**
 * This function is used to return http responses.
 *
 * @param {string} res the result object
 * @param {string} code the http status code
 * @param {string} statusMsg the message containing the status of the message
 * @return an http responde with designated status code and attached
 */
function handleResponse(res, code, statusMsg) {
  res.status(code).json({status: statusMsg});
}



module.exports = router;
