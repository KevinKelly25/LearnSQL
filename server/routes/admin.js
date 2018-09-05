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
const authHelpers = require('../auth/_helpers');
const logger = require('../logs/winston.js');


/**
 * This logs a message that given number of errors will be logged. Used for
 *  testing purposes.
 *
 * @param {string} numberOfExpectedLogs the number of error logs that will be
 *                                       created for testing purposes
 * @return an http response
 */
router.post('/testLogWarning', authHelpers.adminRequired, (req, res, next) => {
  logger.error(`Performing ${req.body.numberOfExpectedLogs} test(s) that`
                 + ' will result in log(s)');
  return res.status(200).json('Log Warning Added Successfully');
});


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
