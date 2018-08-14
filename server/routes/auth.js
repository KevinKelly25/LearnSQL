/**
 * auth.js - LearnSQL
 *
 * Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the routes used for authorization of users
 */



const express = require('express');
const router = express.Router();

const authHelpers = require('../auth/_helpers');
const passport = require('../auth/local');


/**
 * This method create user using a helper function. If an error is encountered
 * an error status code and message is returned
 */
router.post('/register', authHelpers.loginRedirect, (req, res, next)  => {
  return authHelpers.createUser(req, res)
  .catch((err) => {
    handleResponse(res, 500, 'error');
  });
});


/**
 * This method allows a user to log in. First the user is authenticated using
 * passport.js local stategy. If sucessful it will log the user in and serialize
 * the UserID into a session for later authentication. If there is an error or
 * user exists already the relevent status and message is returned.
 */
router.post('/login', authHelpers.loginRedirect, (req, res, next) => {
  passport.authenticate('local', (err, user, info) => {
    if (err) { handleResponse(res, 500, 'error'); }
    if (!user) { handleResponse(res, 404, 'User not found'); }
    if (user) {
      req.logIn(user, function (err) {
        if (err) { handleResponse(res, 500, 'error'); }
        handleResponse(res, 200, 'success');
      });
    }
  })(req, res, next);
});


/**
 * This method logs a user out and removes the userid from the session. It then
 * sends back a sucess response.
 */
router.get('/logout', authHelpers.loginRequired, (req, res, next) => {
  req.logout();
  handleResponse(res, 200, 'success');
});


/**
 * This method returns the deserialized user.
 */
router.get('/check', (req, res, next) => {
  return res.status(200).json(req.user);
});

// *** helpers *** //

/**
 * This function returns a promise with the login function.
 */
 // TODO: explore this functionality more
function handleLogin(req, user) {
  return new Promise((resolve, reject) => {
    req.login(user, (err) => {
      if (err) reject(err);
      resolve();
    });
  });
}


//adds a status code and message to response
function handleResponse(res, code, statusMsg) {
  res.status(code).json({status: statusMsg});
}

module.exports = router;
