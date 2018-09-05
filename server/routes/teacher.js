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
 * @param {string} res the result object
 * @param {string} code the http status code
 * @param {string} statusMsg the message containing the status of the message
 * @return an http responde with designated status code and attached
 */
function handleResponse(res, code, statusMsg) {
  res.status(code).json({ status: statusMsg });
}


/**
 * This method adds a student to a ClassDB database. Most functionality is in
 *  `teacherControlPanel.js` addStudent function but is expecting a promise
 *  to be returned
 *
 * @param {string} username the username of the student to be added
 * @param {string} fullname the full name of the student
 * @param {string} classname the classname the student will be added to
 * @return response
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
 * @param {string} classname the classname the student will be added to
 * @return response
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
 * @param {string} classname the classname the student will be added to
 * @return response
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
 * @param {string} username the username of the student to be added
 * @param {string} classname the classname the student will be added to
 * @return response
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
 * @param {string} name the name of the class to be added
 * @param {string} section the section of the class
 * @param {string} times time the class is supposed to meet
 * @param {string} days the days that the class is supposed to meet
 * @param {string} startDate the date of the first class
 * @param {string} endDate the last day of class
 * @param {string} password the join password students need to join class
 * @return http response if class was added
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
 * @param {string} name the name of the class to be added
 * @return http response if class was dropped
 */
router.post('/dropClass', authHelpers.teacherRequired, (req, res) => teacherHelpers.dropClass(req, res)
  .catch((err) => {
    handleResponse(res, 500, err);
  }));



/**
 * This will redirect a user to the resetPassword page. The reset token needs
 *  to be appended to the end of the link after #?token=. For example
 *  http://localhost:3000/auth/resetPassword/#?token=59ff4734c92f789058b2
 */
router.get('/class/', (res) => {
  res.sendFile(path.join(
    __dirname, '..', '..', 'client', 'views', 'controlPanels', 'teacherClass.html',
  ));
});



module.exports = router;
