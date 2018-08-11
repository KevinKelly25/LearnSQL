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


/**
 * Uses the built in bcypt module to compare given password and database password.
 * This is comparing hashed and salted passwords.
 */
function comparePass(userPassword, databasePassword) {
  return bcrypt.compareSync(userPassword, databasePassword);
}


/**
 * This funciton creates a user in the database. A username is given by
 * the user and has to be unique for the database. The password is then salted and
 * hashed. Using pg-promise the user information is then inserted into the UserData
 * table. If sucessful a success response and message is returned. If there was an
 * error because email already exists that message is returned. Otherwise, the
 * database error is returned
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
        res.status(400).json({status: "Email Already Exists"});
      else if (error.code == '23505' && error.constraint == 'userdata_pkey')//UNIQUE VIOLATION
        res.status(400).json({status: "Username Already Exists"});
      else
        res.status(400).json({status: error});
    })
  })
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
 * to log in. If user is logged in it check to make sure the user is an admin.
 */
function adminRequired(req, res, next) {
  if (!req.user) res.status(401).json({status: 'Please log in'});
  return db.one('SELECT isAdmin FROM UserData WHERE Username = $1', [req.user.username])
  .then((user) => {
    if (!user.isadmin) res.status(401).json({status: 'You are not authorized'});
    return next();
  })
  .catch((err) => {
    res.status(500).json({status: 'Something bad happened'});
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

module.exports = {
  comparePass,
  createUser,
  loginRequired,
  adminRequired,
  loginRedirect
};
