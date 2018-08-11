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

//adds a status code and message to response
function handleResponse(res, code, statusMsg) {
  res.status(code).json({status: statusMsg});
}

module.exports = router;
