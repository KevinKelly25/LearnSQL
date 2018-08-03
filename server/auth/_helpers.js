const bcrypt = require('bcryptjs');
const db = require('../db/ldb.js');
var uniqid = require('uniqid');

function comparePass(userPassword, databasePassword) {
  return bcrypt.compareSync(userPassword, databasePassword);
}



function createUser(req, res) {
  return handleErrors(req)
  .then(() => {
    var _id = uniqid();
    const salt = bcrypt.genSaltSync();
    const hash = bcrypt.hashSync(req.body.password, salt);
    db.none('INSERT INTO UserData(UserID, FullName, Password, Email)  ' +
    'VALUES(${id}, ${full}, ${pass}, ${email})', {
      id: _id,
      full: req.body.fullName,
      pass: hash,
      email: req.body.email
    })
    .then(() => {
        var user = {
          email: req.body.email,
          pass: hash
        }
        //console.log(user);
        return res.status(200).json('User Created Successfully');
    })
    .catch(error => {
      if (error.code == '23505')//UNIQUE VIOLATION
        res.status(400).json({status: "Email Already Exists"});
      else
        res.status(400).json({status: error});
    })
  })
}

function loginRequired(req, res, next) {
  if (!req.user) return res.status(401).json({status: 'Please log in'});
  return next();
}

function adminRequired(req, res, next) {
  if (!req.user) res.status(401).json({status: 'Please log in'});
  return db.one('SELECT isAdmin FROM UserData WHERE UserID = $1', [req.user.username])
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
