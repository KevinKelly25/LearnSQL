/**
 * workshop.js - LearnSQL
 *
 * Christopher Innaco, Michael Torres
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
 *  expects a Promise to be returned
 *
 * @return response
 */
router.get('/getClasses', authHelpers.loginRequired, (req, res) => workshopHelpers.getClasses(req, res)
  .catch((err) => {
    handleResponse(res, 500, err);
  }));


/**
 * This displays the html view which provides the interface to send queries to
 *  classes database.
 */
router.get('/class/', (req, res) => {
  res.sendFile(path.join(
    __dirname, '..', '..', 'client', 'views', 'sandbox.html',
  ));
});

/**
 * This route enables user defined queries from the `sandbox.html` page to be
 *  sent to a specifed database
 */
router.post('/sendQuery', authHelpers.loginRequired, (req, res) => workshopHelpers.sendQuery(req, res)
  .catch((err) => {
    handleResponse(res, 500, err);
  }));

/**
 * This route is executed when the user navigates away from the `sandbox.html` page
 *  in order to close the database connection pool
 */
router.post('/closeConnection', authHelpers.loginRequired, (req, res) => workshopHelpers.closeConnection(req, res)
  .catch((err) => {
    handleResponse(res, 500, err);
  }));

module.exports = router;
