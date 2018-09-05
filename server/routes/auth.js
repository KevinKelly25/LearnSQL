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

const path = require('path');
const authHelpers = require('../auth/_helpers');
const passport = require('../auth/local');

const db = require('../db/ldb.js');
const logger = require('../logs/winston.js');



// *** helpers *** //



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
 * This method create user using a helper function. If an error is encountered
 * an error status code and message is returned
 */
router.post('/register', authHelpers.loginRedirect, (req, res) => authHelpers.createUser(req, res)
  .catch(() => {
    handleResponse(res, 500, 'error');
  }));



/**
 * This method allows a user to log in. First the user is authenticated using
 * passport.js local stategy. If sucessful it will log the user in and serialize
 * the UserID into a session for later authentication. If there is an error or
 * user exists already the relevent status and message is returned.
 */
router.post('/login', authHelpers.loginRedirect, (req, res, next) => {
  passport.authenticate('local', (err, user) => {
    if (err) { handleResponse(res, 500, 'error'); }
    if (!user) { handleResponse(res, 404, 'User Or Password Is Incorrect'); }
    if (user) {
      if (user.isverified === false) {
        handleResponse(res, 404, 'Email Not Verified');
        return;
      }
      req.logIn(user, (error) => {
        if (error) { handleResponse(res, 500, 'error'); }
        handleResponse(res, 200, 'success');
      });
    }
  })(req, res, next);
});



/**
 * This method logs a user out and removes the userid from the session. It then
 * sends back a sucess response.
 */
router.get('/logout', authHelpers.loginRequired, (req, res) => {
  req.logout();
  handleResponse(res, 200, 'success');
});



/**
 * This method returns the deserialized user.
 */
router.get('/check', (req, res) => res.status(200).json(req.user));



/**
 * This method recieves a token and username from the url. It then hashes it and
 *  comapares it to the database verification token. If the tokens match the
 *  user's account will be validated and user will be sent to a success page.
 *  If tokens do not match the user will be sent to a validation failed page.
 *
 * @param token the unhashed token for verification of user account. In URL param
 * @param email the email of the user trying to verify account
 */
// TODO: add timeout for verification token
router.get('/verification/:token/:username', (req, res) => {
  db.task(t => t.one('SELECT Username, Token FROM UserData WHERE Username = $1', [req.params.username])
    .then((data) => {
      if (!authHelpers.compareHashed(req.params.token, data.token)) {
        throw new Error('Token hashes do not match');
      } else {
        return t.none('UPDATE UserData SET isVerified = true WHERE Username = $1', [data.username]);
      }
    }))
    .then(() => {
      res.sendFile(path.join(
        __dirname, '..', '..', 'client', 'views', 'account', 'verificationSuccess.html',
      ));
    })
    .catch((error) => {
      logger.error(`verification: \n${error}`);
      res.sendFile(path.join(
        __dirname, '..', '..', 'client', 'views', 'account', 'verificationError.html',
      ));
    });
});



/**
 * This method sends a forgot password email to a given email. Most functionality
 *  is in `_helpers.js` forgotPassword function but is expecting a promise
 *  to be returned
 *
 * @param {string} email the email that will be used to send forgot password link
 */
router.post('/forgotPasswordEmail', (req, res) => authHelpers.forgotPassword(req, res)
  .catch((err) => {
    handleResponse(res, 500, err);
  }));



/**
 * This will redirect a user to the resetPassword page. The reset token needs
 *  to be appended to the end of the link after #?token=. For example
 *  http://localhost:3000/auth/resetPassword/#?token=59ff4734c92f789058b2
 */
router.get('/resetPassword/', (res) => {
  res.sendFile(path.join(
    __dirname, '..', '..', 'client', 'views', 'account', 'resetPassword.html',
  ));
});



/**
 * This function resets a password of a user. Most functionality
 *  is in `_helpers.js` forgotPassword function but is expecting a promise
 *  to be returned
 *
 * @param {string} username the username that needs password reset
 * @param {string} password the new password of the user
 * @param {string} token token needed for the new password reset
 * @return http response with status message stating whether reset was successful
 */
router.post('/resetPassword', (req, res) => authHelpers.resetPassword(req, res)
  .catch((err) => {
    handleResponse(res, 500, err);
  }));



module.exports = router;
