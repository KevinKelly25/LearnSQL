/**
 * admin.js - LearnSQL
 *
 * Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file sets up the http routes associated with admin functionality
 */



const express = require('express');
const router = express.Router();

const adminHelpers = require('../controlPanel/controlPanel.js');
const authHelpers = require('../auth/_helpers');

const logger = require('../logs/winston.js');



router.post('/testLogWarning', authHelpers.adminRequired,(req, res, next)  => {
    logger.error('Performing ' + req.body.numberOfExpectedLogs + ' test(s) that'
                 + ' will result in log(s)');
    return res.status(200).json('Log Warning Added Successfully');
});



// TODO: refactor addClass and dropClass to teacher.js
/**
 * This method create user using a helper function. If an error is encountered
 * an error status code and message is returned
 */
router.post('/addClass', authHelpers.adminRequired,(req, res, next)  => {
  return adminHelpers.createClass(req, res)
	.catch((err) => {
		handleResponse(res, 500, err);
	});
});




router.post('/dropClass', authHelpers.adminRequired,(req, res, next)  => {
  return adminHelpers.dropClass(req, res)
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
