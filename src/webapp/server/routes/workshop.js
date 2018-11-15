/**
 * workshop.js - LearnSQL
 *
 * Michael Torres
 * Web Applications and Databases for Education (WADE)
 *
 * This file sets up the http routes associated with getting classes
 *  for all users functionality
 */

const express = require('express');
const router = express.Router();
const path = require('path');
const workshopHelpers = require('../controlPanel/workshopControlPanel.js');
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
 * This method returns the classes for the user logged in. Most
 *  functionality is in `workshopControlPanel.js` getClasses function.
 *  expects a promise to be returned
 *
 * @return response
 */
router.get('/getClasses', authHelpers.loginRequired, (req, res) => workshopHelpers.getClasses(req, res)
  .catch((err) => {
    handleResponse(res, 500, err);
  }));

/**
 * This will redirect a user to the resetPassword page. The reset token needs
 *  to be appended to the end of the link after #?token=. For example
 *  http://localhost:3000/auth/resetPassword/#?token=59ff4734c92f789058b2
 */
router.get('/class/', (req, res) => {
  res.sendFile(path.join(
    __dirname, '..', '..', 'client', 'views', 'sandbox.html',
  ));
});

module.exports = router;