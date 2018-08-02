const bcrypt = require('bcryptjs');
const db = require('../db/ldb.js');

function comparePass(userPassword, databasePassword) {
  return bcrypt.compareSync(userPassword, databasePassword);
}

function createUser(req, res) {
  //// TODO: npm i uniqid
  return handleErrors(req)
  .then(() => {
    console.log('reached then');
    var _id = (Date.now().toString(36) + Math.random().toString(36).substr(2,5)).toUpperCase();
    console.log(_id);
    const salt = bcrypt.genSaltSync();
    const hash = bcrypt.hashSync(req.body.password, salt);
    db.none('INSERT INTO Users(UserID, FullName, Password, Email)  ' +
    'VALUES(${id}, ${full}, ${pass}, ${email})', {
      id: _id,
      full: req.body.fullName,
      pass: hash,
      email: req.body.email,
    })
    .then(() => {
        res.status(200).json({status: 'User was created'});
    })
    .catch(error => {
        res.status(500).json({status: 'User could not be created'});
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
  // TODO: fix length requirements
  console.log(req.body);
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
