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
const path = require('path');
const teacherHelpers = require('../controlPanel/teacherControlPanel.js');
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
 * This method adds a student to a ClassDB database. Most functionality is in
 *  `teacherControlPanel.js` addStudent function but is expecting a promise
 *  to be returned
 *
 * @param {string} username The username of the student to be added
 * @param {string} fullname The full name of the student
 * @param {string} classname The classname the student will be added to
 * @return Response
 */
router.post('/addStudent', authHelpers.teacherRequired, (req, res) => teacherHelpers.addStudent(req, res)
  .catch((err) => {
    handleResponse(res, 500, err);
  }));



/**
 * This method returns the classes the teacher created. Most
 *  functionality is in `teacherControlPanel.js` getClasses function.
 *  expects a promise to be returned
 *
 * @return response
 */
router.get('/getClasses', authHelpers.teacherRequired, (req, res) => teacherHelpers.getClasses(req, res)
  .catch((err) => {
    handleResponse(res, 500, err);
  }));



/**
 * This method returns class information from a ClassDB database. Most
 *  functionality is in `teacherControlPanel.js` getClass function.
 *  expects a promise to be returned
 *
 * @param {string} classname Rhe classname the student will be added to
 * @return Response
 */
router.post('/getClassInfo', authHelpers.teacherRequired, (req, res) => teacherHelpers.getClassInfo(req, res)
  .catch((err) => {
    handleResponse(res, 500, err);
  }));



/**
 * This method returns student information from a ClassDB database. Most
 *  functionality is in `teacherControlPanel.js` getStudents function.
 *  expects a promise to be returned
 *
 * @param {string} classname The classname the student will be added to
 * @return Response
 */
router.post('/getStudents', authHelpers.teacherRequired, (req, res) => teacherHelpers.getStudents(req, res)
  .catch((err) => {
    handleResponse(res, 500, err);
  }));



/**
 * This method removes a student from a ClassDB database. Most functionality is
 *  contained in `teacherControlPanel.js` dropStudent function. Expects a
 *  promise to be returned
 *
 * @param {string} username The username of the student to be added
 * @param {string} classname The classname the student will be added to
 * @return Response
 */
router.post('/dropStudent', authHelpers.teacherRequired, (req, res) => teacherHelpers.dropStudent(req, res)
  .catch((err) => {
    handleResponse(res, 500, err);
  }));



/**
 * This method creates a class for the teacher. Most functionality is
 *  contained in `teacherControlPanel.js` createClass function. Expects a
 *  promise to be returned
 *
 *
 * @param {string} name The name of the class to be added
 * @param {string} section The section of the class
 * @param {string} times Time the class is supposed to meet
 * @param {string} days The days that the class is supposed to meet
 * @param {string} startDate The date of the first class
 * @param {string} endDate The last day of class
 * @param {string} password The join password students need to join class
 * @return Http response if class was added
 */
router.post('/addClass', authHelpers.teacherRequired, (req, res) => teacherHelpers.createClass(req, res)
  .catch((err) => {
    handleResponse(res, 500, err);
  }));



/**
 * This method drops a class for the teacher. Most functionality is
 *  contained in `teacherControlPanel.js` dropClass function. Expects a
 *  promise to be returned
 *
 *
 * @param {string} name The name of the class to be added
 * @return Http response if class was dropped
 */
router.post('/dropClass', authHelpers.teacherRequired, (req, res) => teacherHelpers.dropClass(req, res)
  .catch((err) => {
    handleResponse(res, 500, err);
  }));

/**
 * This method creates a team in a ClassDB instance. Most functionality is
 *  contained in `teacherControlPanel.js` createTeam function. Expects a
 *  promise to be returned
 *
 * @param {string} classID The class id of the class being added to
 * @param {string} teamName The name of the team to be added
 * @param {string} section The full name of the team
 * @return Http response if class was added
 */
router.post('/addTeam', authHelpers.teacherRequired, (req, res) => {
  teacherHelpers.createTeam(req, res)
  .catch((err) => {
    handleResponse(res, 500, err);
  });
 });




/**
 * This will redirect a user to the class page. The class name and section needs
 *  to be appended to the end of the link. For example
 *  http://localhost:3000/teacher/class/#?class=cs305&section=71
 */
router.get('/class/', (req, res) => {
  res.sendFile(path.join(
    __dirname, '..', '..', 'client', 'views', 'controlPanels', 'teacherClass.html',
  ));
});



module.exports = router;
