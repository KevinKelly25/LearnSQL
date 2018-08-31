/**
 * user.js - LearnSQL
 *
 * Christopher Innaco, Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file sets up the HTTP routes associated with users
 */

const express = require('express');
const router = express.Router();

const userHelpers = require('../controlPanel/userControlPanel.js');
const authHelpers = require('../auth/_helpers');


// TODO: define and explain route better as this is currently unused
router.get('/user', authHelpers.loginRequired, (req, res, next)  => {
  handleResponse(res, 200, 'success');
});

// TODO: define and explain route better as this is currently unused
router.get('/admin', authHelpers.adminRequired, (req, res, next)  => {
  handleResponse(res, 200, 'success');
});

/**
 * This method allows users to edit their personal information stored in
 * the `userdata` table in the LearnSQL database. 
 * Most of functionality resides in the `userControlPanel.js` editInformation function.
 *
 */
router.post('/editInformation', authHelpers.loginRequired, (req, res, next)  => {	
	return userHelpers.editInformation(req, res)
	.catch((err) => {
		console.log("ERROR: "+ err);
		handleResponse(res, 500, err);
	});
});

/**
 * This method enables a user who updated their username to log back in automatically 
 * Most of functionality resides in the `userControlPanel.js` getPassword function.
 *
 */
router.post('/getPassword', authHelpers.loginRequired, (req, res, next)  => {	
	return userHelpers.editInformation(req, res)
	.catch((err) => {
		console.log("ERROR: "+ err);
		handleResponse(res, 500, err);
	});
});

//adds a status code and message to response
function handleResponse(res, code, statusMsg) {
  res.status(code).json({status: statusMsg});
}

module.exports = router;
