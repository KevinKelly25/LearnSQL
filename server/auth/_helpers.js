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
const ldb = require('../db/ldb.js');
const logger = require('../logs/winston.js');
const cryptoRandomString = require('crypto-random-string');
const nodemailer = require('nodemailer');


/**
 * Uses the built in bcrypt module to compare given plain string to an already
 *  hashed string.
 *
 * @param {string} unhashedString a string that needs to be hashed and salted for comparision
 * @param {string} hashedString already hashed string that will compared
 * @return a boolean on whether the passwords match after salting/hashing
 */
function compareHashed(unhashedString, hashedString) {
  return bcrypt.compareSync(unhashedString, hashedString);
}


/**
 * This function creates a user in the database. A username is given by
 *  the user and has to be unique for the database. The password is then salted and
 *  hashed. Using pg-promise the user information is then inserted into the UserData
 *  table. If successful a success response and message is returned. If there was an
 *  error because email already exists that message is returned. Otherwise, the
 *  database error is returned
 *
 * @param {string} password the password the user wants to use
 * @param {string} username the username the user wants to use
 * @param {string} fullName the full name of the user
 * @param {string} email the email the user wants to use
 * @return http response with status message
 */
function createUser(req, res) {
  return handleErrors(req)
  .then(() => {
    console.log(req.body);
    const passSalt = bcrypt.genSaltSync();
    const hashedPass = bcrypt.hashSync(req.body.password, passSalt);
    const token = cryptoRandomString(20);
    const hashSalt = bcrypt.genSaltSync();
    const hashedToken = bcrypt.hashSync(token, hashSalt);
    const email = req.body.email;
    ldb.none('INSERT INTO UserData(Username, FullName, Password, Email, token)  ' +
    'VALUES(${username}, ${full}, ${pass}, ${email}, ${token})', {
      username: req.body.username,
      full: req.body.fullName,
      pass: hashedPass,
      email: req.body.email,
      token: hashedToken
    })
    .then(() => {
        req.body= {
            receiver : email,
            prompt : 'Click this link to verify your account',
            content : 'http://localhost:3000/auth/verification/' + token + '/' +
                      req.body.username + '<br>' +
                      'Link will expire in 30 minutes',
            emailTitle: 'LearnSQL Email Verification',
            successMessage: 'Email Verification Sent'
        };
        sendEmail(req, res);
    })
    .catch(error => {
        console.log('getting to this error');
        console.log(error);
      if (error.code == '23505' && error.constraint == 'idx_unique_email')//UNIQUE VIOLATION
        return res.status(400).json({status: "Email Already Exists"});
      else if (error.code == '23505' && error.constraint == 'userdata_pkey')//UNIQUE VIOLATION
        return res.status(400).json({status: "Username Already Exists"});
      else
        logger.error('createUser: \n' + error);
        return res.status(400).json({status: error});
    })
  })
}



/**
 * This function sends an email with forgotPassword details to a given email
 *  address. If the email is in UserData table it will send a link with generated
 *  token. If not registed will send a general email explaining that the email
 *  is not registered on the site.
 *
 * @param {string} email the email that will be used to send forgot password link
 * @return http response with status message
 */
 // TODO: add timeout for verification token
function forgotPassword(req, res) {
    return new Promise((resolve, reject) => {
      return ldb.task(t => {
        return t.oneOrNone('SELECT Email FROM UserData WHERE Email = $1 ', [req.body.email])
        .then(result => {
          if (result) {
            const token = cryptoRandomString(20);
            const salt = bcrypt.genSaltSync();
            const hashedToken = bcrypt.hashSync(token, salt);
            const email = result.email;
            return t.none('UPDATE USERDATA SET Token = $1, forgotPassword '
                          + '= true WHERE Email = $2 ',[hashedToken,   email])
            .then(() => {
              req.body= {
                receiver : email,
                prompt : 'Use this link to renew your password',
                content : 'http://localhost:3000/auth/resetPassword/#?token=' + token,
                emailTitle: 'LearnSQL Forgot Password Reset',
                successMessage: 'Email being sent to that address'
              };
              resolve();
              sendEmail(req, res);
            });
          } else {
              req.body= {
              receiver : req.body.email,
              prompt : 'Password Reset Attempt Failed',
              content :  'This Email was used to try to reset a password for'
              + 'LearnSQL, however, there is no associated account linked to this address',
              emailTitle: 'Requested Password Reset LearnSQL',
              successMessage: 'Email being sent to that address'
          };
            resolve();
            sendEmail(req, res);
          }
      })
    })
    .catch((error) => {
      logger.error('forgotPassword: \n' + error);
      reject({
        message: 'Email Processing Failed'
      });
      return;
    });
  });
}


/**
 * This function resets a password of a user. When given a username it extracts
 *  what is supposed to be the correct hashed token and compares the given token
 *  to the hashed token. If matched and forgotPassword is true the password is
 *  updated to the given new password
 *
 * @param {string} username the username that needs password reset
 * @param {string} password the new password of the user
 * @param {string} token token needed for the new password reset
 * @return http response with status message stating whether reset was successful
 */
 // TODO: add timeout for verification token
function resetPassword(req, res) {
  return new Promise((resolve, reject) => {
    ldb.task(t => {
      return t.one('SELECT Username, Token, forgotPassword FROM UserData ' +
                   ' WHERE Username = $1', [req.body.username])
      .then(data => {
        console.log(data);
        if (!compareHashed(req.body.token, data.token)) {
          throw 'Token hashes do not match';
        } else if (!data.forgotpassword) {
          throw 'ForgotPassword not true';
        } else {
          const passSalt = bcrypt.genSaltSync();
          const hashedPass = bcrypt.hashSync(req.body.password, passSalt);
          return t.none('UPDATE UserData SET forgotPassword = false, password = $1'
                        + ' WHERE Username = $2',[hashedPass, data.username]);
          }
        })
    })
    .then(() => {
      return res.status(200).json('Password Reset Successfully');
    })
    .catch((error) =>{
      console.log(error);
      logger.error('reset Password: \n' + error);
      reject('Username or Token does not match');
      return;
    });
  });
}



/**
 * If a user is not logged in returns a 401 status code and a status that says
 * to log in.
 */
function loginRequired(req, res, next) {
  if (!req.user) return res.status(401).json({status: 'Please log in'});
  return next();
}


/**
 * If a user is not logged in returns a 401 status code and a status that says
 * to log in. If user is logged in it checks to make sure the user is an admin.
 */
function adminRequired(req, res, next) {
  if (!req.user) return res.status(401).json({status: 'Please log in'});
  return ldb.one('SELECT isAdmin FROM UserData WHERE Username = $1', [req.user.username])
  .then((user) => {
    if (!user.isadmin) return res.status(401).json({status: 'You are not authorized'});
    return next();
  })
  .catch((err) => {
    return res.status(500).json({status: 'Something bad happened'});
  });
}



/**
 * If a user is not logged in returns a 401 status code and a status that says
 * to log in. If user is logged in it checks to make sure the user is a teacher.
 *
 */
function teacherRequired(req, res, next) {
  if (!req.user) return res.status(401).json({status: 'Please log in'});
  return ldb.one('SELECT isAdmin, isTeacher FROM UserData WHERE Username = $1', [req.user.username])
  .then((user) => {
    console.log(user);
    if (!user.isadmin && !user.isteacher) return res.status(401).json({status: 'You are not authorized'});
    return next();
  })
  .catch((err) => {
    return res.status(500).json({status: 'Something bad happened'});
  });
}



/**
 * If a user is not logged in returns a 401 status code and a status that says
 * to log in. If user is logged in it checks to make sure the user is a student.
 *
 */
function studentRequired(req, res, next) {
  if (!req.user) return res.status(401).json({status: 'Please log in'});
  return ldb.one('SELECT isAdmin, isstudent FROM UserData WHERE Username = $1', [req.user.username])
  .then((user) => {
    console.log(user);
    if (!user.isadmin && !user.isstudent) return res.status(401).json({status: 'You are not authorized'});
    return next();
  })
  .catch((err) => {
    return res.status(500).json({status: 'Something bad happened'});
  });
}



/**
 * If a user is logged in returns a 401 status code and a status that says
 * already logged in.
 */
function loginRedirect(req, res, next) {
  if (req.user) return res.status(401).json(
    {status: 'You are already logged in'});
  return next();
}

/**
 * handles errors when registering. For now only checks the length of the password
 * Also, set to a low number for testing purposes.
 *
 * @param {string} password password the user wishes to use
 */
function handleErrors(req) {
  // TODO: fix length requirements
  return new Promise((resolve, reject) => {
    if (req.body.password.length < 1) {
      reject({
        message: 'Password must be longer than 6 characters'
      });
    } else {
      resolve();
    }
  });
}


/**
 * Sends an email to a given email address. The contents and subject of the email
 *  has to be given to the function. Content and subject is html driven.
 *
 * @param {string} prompt H3 header of the email
 * @param {string} content The content of the email, can be html
 * @param {string} receiver Address that the email is being sent to
 * @param {string} emailTitle email subjectline/title
 * @param {string} successMessage The message that will be http response upon
 *                                 success of the email
 */
function sendEmail(req, res) {
  const output = `
        <h3>${req.body.prompt}</h3>
        <p>${req.body.content}</p>
    `;

  let transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com', // host for outlook mail
    port: 587,
    //secure: false, // true for 465, false for other ports
    auth: {
        user: 'learnsqltesting@gmail.com', // email used for sending the message (will need to be changed)
        pass: 'testing123!'
    },
    tls:{
        // rejectUnauthorized:false will probably need to be changed for production because
        // it can leave you vulnerable to MITM attack - secretly relays and alters the
        // communication betwee two parties.
        rejectUnauthorized:false
    }
  });

  // setup email data with unicode symbols
  let mailOptions = {
    from: '"LearnSQL" <learnsqltesting@gmail.com>', // sender address
    to: req.body.receiver, // list of receivers (email will need to be changed)
    subject: req.body.emailTitle, // Subject line
    html: output // html body
  };

  // send mail with defined transport object
  transporter.sendMail(mailOptions, (error, info) => {
    if (error) {
      logger.error('sendEmail: \n' + error);
      console.log(error);
      return res.status(500).json({status: 'Could Not Send Email'});
    }
    console.log('Message sent: %s', info.messageId);
    console.log('Preview URL: %s', nodemailer.getTestMessageUrl(info));

    return res.status(200).json({status: req.body.successMessage});
  });
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
  resetPassword
};
