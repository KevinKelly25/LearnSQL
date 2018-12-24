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
 * This function is used to return http responses.
 *
 * @param {string} res The result object
 * @param {string} code The http status code
 * @param {string} statusMsg The message containing the status of the message
 * @return An http response with designated status code and attached
 */
function handleResponse(res, code, statusMsg) {
  res.status(code).json({ status: statusMsg });
}



/**
 * This method returns class information from a ClassDB database. Most
 *  functionality is in `studentControlPanel.js` getClass function.
 *
 * @return Http response on if the student was successfully added with attached
 *          object which has the classes the user is in and relevant class
 *          information
 */
router.get('/getClasses', authHelpers.loginRequired, (req, res) => studentHelpers.getClasses(req, res)
  .catch((err) => {
    handleResponse(res, 500, err);
  }));


/**
 * This method returns class information from a ClassDB database. Most
 *  functionality is in `studentControlPanel.js` getClass function.
 *
 * @param {string} classID The classID of the class the teams are in
 * @return Http response on of all teams student is in for a given class
 */
router.post('/getTeams', authHelpers.loginRequired, (req, res) => {
  studentHelpers.getTeams(req, res)
    .catch((err) => {
      handleResponse(res, 500, err);
    });
});


/**
 * This method adds a student to a ClassDB database as well as Attends table.
 *  Most functionality is in `studentControlPanel.js` addStudent function.
 *
 * @param {string} password The password used in order to join class
 * @param {string} classID The class id of the class the student will be added to
 * @return http response on if the student was successfully added
 */
router.post('/joinClass', authHelpers.loginRequired, (req, res) => studentHelpers.addStudent(req, res)
  .catch((err) => {
    handleResponse(res, 500, err);
  }));



module.exports = router;
