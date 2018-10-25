/**
 * _helpers.js - LearnSQL
 *
 * Kevin Kelly, Michael Torres
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the helper functions for the http methods relating to the
 * authentication of users
 */


const bcrypt = require('bcryptjs');
const cryptoRandomString = require('crypto-random-string');
const nodemailer = require('nodemailer');
const ldb = require('../db/ldb.js');
const logger = require('../logs/winston.js');



/**
 * Handles errors when registering. For now only checks the length of the password
 *  Also, set to a low number for testing purposes.
 *
 * @param {string} password password the user wishes to use
 */
function handleErrors(req) {
  // TODO: fix length requirements
  return new Promise((resolve, reject) => {
    if (req.body.password.length < 1) {
      reject(new Error('Password must be longer than 1 character'));
    } else {
      resolve();
    }
  });
}



/**
 * Uses the built in bcrypt module to compare given plain string to an already
 *  hashed string.
 *
 * @param {string} unhashedString A string that needs to be hashed and salted for comparison
 * @param {string} hashedString Already hashed string that will compared
 * @return A boolean on whether the passwords match after salting/hashing
 */
function compareHashed(unhashedString, hashedString) {
  return bcrypt.compareSync(unhashedString, hashedString);
}



/**
 * Sends an email to a given email address. The contents and subject of the email
 *  has to be given to the function. Content and subject is html driven.
 *
 * @param {string} prompt H3 header of the email
 * @param {string} content The content of the email, can be html
 * @param {string} receiver Address that the email is being sent to
 * @param {string} emailTitle Email subjectline/title
 * @param {string} successMessage The message that will be http response upon
 *                                 success of the email
 */
function sendEmail(req, res) {
  const output = `
        <h3>${req.body.prompt}</h3>
        <p>${req.body.content}</p>
    `;

  const transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com', // host for outlook mail
    port: 587,
    // Secure: false, // true for 465, false for other ports
    auth: {
      user: 'learnsqltesting@gmail.com', // email used for sending the message (will need to be changed)
      pass: 'testing123!',
    },
    tls: {
      // RejectUnauthorized:false will probably need to be changed for production because
      //  it can leave you vulnerable to MITM attack - secretly relays and alters the
      //  communication betwee two parties.
      rejectUnauthorized: false,
    },
  });

  // Setup email data with unicode symbols
  const mailOptions = {
    from: '"LearnSQL" <learnsqltesting@gmail.com>', // sender address
    to: req.body.receiver, // list of receivers (email will need to be changed)
    subject: req.body.emailTitle, // Subject line
    html: output, // html body
  };

  // Send mail with defined transport object
  transporter.sendMail(mailOptions, (error) => {
    if (error) {
      logger.error(`sendEmail: \n${error}`);
      return res.status(500).json({ status: 'Could Not Send Email' });
    }

    return res.status(200).json({ status: req.body.successMessage });
  });
}



/**
 * This function creates a user in the database. A username is given by
 *  the user and has to be unique for the database. Using pg-promise the user
 *  information is then inserted into the UserData via the CreateUser function
 *  in the database. If successful a success response and message is returned.
 *  If there was an error the database error is returned
 *
 * @param {string} password The password the user wants to use
 * @param {string} username The username the user wants to use
 * @param {string} fullName The full name of the user
 * @param {string} email The email the user wants to use
 * @return Http response with status message
 */
function createUser(req, res) {
  return handleErrors(req)
    .then(() => {
      const token = cryptoRandomString(20);
      const { email } = req.body;
      // Create user with CreateUser function on db
      ldb.func('LearnSQL.createUser',
        [req.body.username, req.body.fullName, req.body.password, email, token])
        .then(() => {
          req.body = {
            receiver: email,
            prompt: 'Click this link to verify your account',
            content: `http://localhost:3000/auth/verification/${token}/${
              req.body.username}<br>`
                    + 'Link will expire in 30 minutes',
            emailTitle: 'LearnSQL Email Verification',
            successMessage: 'Email Verification Sent',
          };
          sendEmail(req, res);
        })
        .catch((error) => {
          // If known error send that known error back, otherwise send back general
          //  server error response
          if (error.constraint === 'idx_unique_email') {
            return res.status(400).json('Email Already Exists');
          }
          if (error.constraint === 'userdata_t_pkey') {
            return res.status(400).json('Username Already Exists');
          }
          logger.error(`createUser: \n${error}`);
          return res.status(500).json('Server Error - User could not be added');
        });
    });
}



/**
 * This function sends an email with forgotPassword details to a given email
 *  address. If the email is in UserData table it will send a link with generated
 *  token. If not registed will send a general email explaining that the email
 *  is not registered on the site.
 *
 * @param {string} email The email that will be used to send forgot password link
 * @return Http response with status message
 */
// TODO: add timeout for verification token
function forgotPassword(req, res) {
  return new Promise((resolve, reject) => ldb.task(
    t => t.oneOrNone('SELECT Email FROM LearnSQL.UserData WHERE Email = $1 ',
      [req.body.email])
      .then((result) => {
        if (result) {
          const token = cryptoRandomString(20);
          const { salt } = bcrypt.genSaltSync();
          const hashedToken = bcrypt.hashSync(token, salt);
          const { email } = result;
          return t.none('UPDATE LearnSQL.USERDATA SET Token = $1, forgotPassword '
                          + '= true WHERE Email = $2 ', [hashedToken, email])
            .then(() => {
              req.body = {
                receiver: email,
                prompt: 'Use this link to renew your password',
                content: `http://localhost:3000/auth/resetPassword/#?token=${token}`,
                emailTitle: 'LearnSQL Forgot Password Reset',
                successMessage: 'Email being sent to that address',
              };
              resolve();
              sendEmail(req, res);
            });
        }
        req.body = {
          receiver: req.body.email,
          prompt: 'Password Reset Attempt Failed',
          content: 'This Email was used to try to reset a password for'
              + 'LearnSQL, however, there is no associated account linked to this address',
          emailTitle: 'Requested Password Reset LearnSQL',
          successMessage: 'Email being sent to that address',
        };
        resolve();
        return sendEmail(req, res);
      }),
  )
    .catch((error) => {
      logger.error(`forgotPassword: \n${error}`);
      reject(new Error('Email Processing Failed'));
    }));
}



/**
 * If a user is not logged in returns a 401 status code and a status that says
 *  to log in.
 */
function loginRequired(req, res, next) {
  if (!req.user) return res.status(401).json({ status: 'Please log in' });
  return next();
}



/**
 * If a user is not logged in returns a 401 status code and a status that says
 *  to log in. If user is logged in it checks to make sure the user is an admin.
 */
function adminRequired(req, res, next) {
  if (!req.user) return res.status(401).json({ status: 'Please log in' });
  return ldb.one('SELECT isAdmin FROM LearnSQL.UserData WHERE Username = $1',
    [req.user.username])
    .then((user) => {
      if (!user.isadmin) {
        return res.status(401).json({ status: 'You are not authorized' });
      }
      return next();
    })
    .catch(() => res.status(500).json({ status: 'Something bad happened' }));
}



/**
 * If a user is not logged in returns a 401 status code and a status that says
 *  to log in. If user is logged in it checks to make sure the user is a teacher.
 *
 */
function teacherRequired(req, res, next) {
  if (!req.user) return res.status(401).json({ status: 'Please log in' });
  return ldb.one('SELECT isAdmin, isTeacher FROM LearnSQL.UserData WHERE Username = $1',
    [req.user.username])
    .then((user) => {
      if (!user.isadmin && !user.isteacher) {
        return res.status(401).json({ status: 'You are not authorized' });
      }
      return next();
    })
    .catch(() => res.status(500).json({ status: 'Something bad happened' }));
}



/**
 * If a user is not logged in returns a 401 status code and a status that says
 *  to log in. If user is logged in it checks to make sure the user is a student.
 *
 */
function studentRequired(req, res, next) {
  if (!req.user) return res.status(401).json({ status: 'Please log in' });
  return ldb.one('SELECT isAdmin, isstudent FROM LearnSQL.UserData WHERE Username = $1',
    [req.user.username])
    .then((user) => {
      if (!user.isadmin && !user.isstudent) {
        return res.status(401).json({ status: 'You are not authorized' });
      }
      return next();
    })
    .catch(() => res.status(500).json({ status: 'Something bad happened' }));
}



/**
 * If a user is logged in returns a 401 status code and a status that says
 *  already logged in.
 */
function loginRedirect(req, res, next) {
  if (req.user) {
    return res.status(401).json(
      { status: 'You are already logged in' },
    );
  }
  return next();
}



module.exports = {
  compareHashed,
  createUser,
  loginRequired,
  adminRequired,
  teacherRequired,
  studentRequired,
  loginRedirect,
  forgotPassword,
};
