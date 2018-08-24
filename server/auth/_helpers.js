/**
 * _helpers.js - LearnSQL
 *
 * Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the helper functions for the http methods relating to the
 * authentication of users
 */



const bcrypt = require('bcryptjs');
const db = require('../db/ldb.js');

const logger = require('../logs/winston.js');


/**
 * Uses the built in bcrypt module to compare given password and database password.
 *  This is comparing hashed and salted passwords.
 *
 * @param {string} userPassword user inputted password
 * @param {string} databasePassword password from the database
 * @return a boolean on whether the passwords match after salting/hashing
 */
function comparePass(userPassword, databasePassword) {
  return bcrypt.compareSync(userPassword, databasePassword);
}


/**
 * This funciton creates a user in the database. A username is given by
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
 * @return http response with message
 */
function createUser(req, res) {
  return handleErrors(req)
  .then(() => {
    const salt = bcrypt.genSaltSync();
    const hash = bcrypt.hashSync(req.body.password, salt);
    db.none('INSERT INTO UserData(Username, FullName, Password, Email)  ' +
    'VALUES(${username}, ${full}, ${pass}, ${email})', {
      username: req.body.username,
      full: req.body.fullName,
      pass: hash,
      email: req.body.email
    })
    .then(() => {
        return res.status(200).json('User Created Successfully');
    })
    .catch(error => {
      //console.log(error.error);
      if (error.code == '23505' && error.constraint == 'idx_unique_email')//UNIQUE VIOLATION
        return res.status(400).json({status: "Email Already Exists"});
      else if (error.code == '23505' && error.constraint == 'userdata_pkey')//UNIQUE VIOLATION
        return res.status(400).json({status: "Username Already Exists"});
      else
        return res.status(400).json({status: error});
    })
  })
}



/**
 * This function adds a student to a ClassDB database. Using the given classname
 *  and the user's username a ClassID is derived; the ClassID is also the ClassDB
 *  database name. Using the ClassID a connection is made to the database and a
 *  database object is returned. This db object then uses the given username and
 *  fullname to create a student in the ClassDB database. To do this a built in
 *  classdb function 'createStudent' is used. See https://github.com/DASSL/ClassDB/wiki/Adding-Users
 *  for more information on how ClassDB adds students
 *
 * @param {string} email the username of the student to be added
 * @param {string} fullname the full name of the student
 * @param {string} classname the classname the student will be added to
 * @return response with boolean whether or not the email exists
 */
function forgotPassword(req, res) {
    return new Promise((resolve, reject) => {
        return db.oneOrNone('SELECT Email FROM UserData WHERE Email = $1 ', [req.body.email])
        .then((result) => {
            //if the email existed
            if (result) {
                req.body= {
                    prompt : 'Click this link to renew your password'
                }
                console.log(req.body);
                //sendEmail(req, res);
            } else {
                res.status(200).json('If email exists, an email will be sent to '
                                    +'that address');
                return false;
            }
        })
        .catch((error) => {//goes here if you can't find the class
            logger.error('checkEmail: \n' + error);
            reject({
                message: 'Email Processing Failed'
            });
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
  return db.one('SELECT isAdmin FROM UserData WHERE Username = $1', [req.user.username])
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
 */
function teacherRequired(req, res, next) {
  if (!req.user) return res.status(401).json({status: 'Please log in'});
  return db.one('SELECT isAdmin, isTeacher FROM UserData WHERE Username = $1', [req.user.username])
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



function sendEmail(req, res) {
  const output = `
        <h3>${req.body.prompt}</h3>
        <p>${req.body.content}</p>
    `;

  let transporter = nodemailer.createTransport({
    host: 'smtp-mail.outlook.com', // host for outlook mail
    port: 587,
    secure: false, // true for 465, false for other ports
    auth: {
        user: 'test123203@outlook.com', // email used for sending the message (will need to be changed)
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
      from: '"Nodemailer app 👻" <test123203@outlook.com>', // sender address
      to: req.body.receiver, // list of receivers (email will need to be changed)
      subject: req.body.emailTitle, // Subject line
      html: output // html body
  };

  // send mail with defined transport object
  transporter.sendMail(mailOptions, (error, info) => {
      if (error) {
          console.log(error);
          return res.status(500).json({status: 'Email could not be sent'});
      }
      console.log('Message sent: %s', info.messageId);
      console.log('Preview URL: %s', nodemailer.getTestMessageUrl(info));

      return res.status(200).json({status: 'email sent'});
  });
}

module.exports = {
  comparePass,
  createUser,
  loginRequired,
  adminRequired,
  teacherRequired,
  loginRedirect,
  forgotPassword
};
