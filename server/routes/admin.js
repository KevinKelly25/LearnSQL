const express = require('express');
const router = express.Router();

const adminHelpers = require('../controlPanel/controlPanel.js');
const authHelpers = require('../auth/_helpers');


/**
 * This method create user using a helper function. If an error is encountered
 * an error status code and message is returned
 */
router.post('/addClass', authHelpers.adminRequired, (req, res, next)  => {
  return adminHelpers.createClass(req, res)
	.then((result)=> {
		return done(null, result);
	})
	.catch((err) => {
		return done(null, false, {message: err});
	})(req, res, next);
});

module.exports = router;
