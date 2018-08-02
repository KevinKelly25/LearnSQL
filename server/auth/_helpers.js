const bcrypt = require('bcryptjs');
const db = require('../db/ldb.js');

function comparePass(userPassword, databasePassword) {
  return bcrypt.compareSync(userPassword, databasePassword);
}

function createUser(req, res) {
  return handleErrors(req)
  .then(() => {
    const salt = bcrypt.genSaltSync();
    const hash = bcrypt.hashSync(req.body.password, salt);
    db.none('INSERT INTO Users(UserID, FullName, Password, Email)  ' +
    'VALUES(${id}, ${full}, ${pass}, ${email})', {
      id: req.body.username,
      full: req.body.fullname,
      pass: hash,
      email: req.body.email,
    })
    .then(() => {
        // success;
    })
    .catch(error => {
        // error;
    })
  })
}

function loginRequired(req, res, next) {
  if (!req.user) return res.status(401).json({status: 'Please log in'});
  return next();
}

function adminRequired(req, res, next) {
  if (!req.user) res.status(401).json({status: 'Please log in'});
  return db.one('SELECT isAdmin FROM Users WHERE UserID = $1', [req.user.username])
  .then((user) => {
    if (!user.isAdmin) res.status(401).json({status: 'You are not authorized'});
    return next();
  })
  .catch((err) => {
    res.status(500).json({status: 'Something bad happened'});
  });
}

function loginRedirect(req, res, next) {
  if (req.user) return res.status(401).json(
    {status: 'You are already logged in'});
  return next();
}

function handleErrors(req) {
  return new Promise((resolve, reject) => {
    if (req.body.username.length < 6) {
      reject({
        message: 'Username must be longer than 6 characters'
      });
    }
    else if (req.body.password.length < 6) {
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
