/**
 * student.js - LearnSQL
 *
 * Michael Torres, Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file sets up the http routes associated with student functionality
 */


const express = require('express');

const router = express.Router();

const studentHelpers = require('../controlPanel/studentControlPanel.js');
const authHelpers = require('../auth/_helpers');


/**
 * This method returns class information from a ClassDB database. Most
 *  functionality is in `studentControlPanel.js` getClass function.
 *
 * @return http response on if the student was successfully added with attached
 *          object which has the classes the user is in and relevant class
 *          information
 */
router.get('/getClasses', authHelpers.studentRequired, (req, res, next) => studentHelpers.getClasses(req, res)
  .catch((err) => {
    handleResponse(res, 500, err);
  }));


/**
 * This method adds a student to a ClassDB database as well as Attends table.
 *  Most functionality is in `studentControlPanel.js` addStudent function.
 *
 * @param {string} password the password used in order to join class
 * @param {string} classID the class id of the class the student will be added to
 * @return http response on if the student was successfully added
 */
router.post('/joinClass', authHelpers.loginRequired, (req, res, next) => studentHelpers.addStudent(req, res)
  .catch((err) => {
    handleResponse(res, 500, err);
  }));


/**
 * This function is used to return http responses.
 *
 * @param {string} res the result object
 * @param {string} code the http status code
 * @param {string} statusMsg the message containing the status of the message
 * @return an http response with designated status code and attached
 */
function handleResponse(res, code, statusMsg) {
  res.status(code).json({ status: statusMsg });
}


module.exports = router;
