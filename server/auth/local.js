const passport = require('passport');
const LocalStrategy = require('passport-local').Strategy;
const authHelpers = require('./_helpers');
const init = require('./passport');
const pgp = require('pg-promise')();
var db = require('../db/ldb.js')

init();


/**
 * This function sets up the local stategy for the passport.js module. usernameField
 * and passwordField are set to the database equivalient of their names.
 * Using pg-promise the query returns userdata if there is a matching userid
 */
passport.use(new LocalStrategy({
  usernameField: 'email',
  passwordField: 'password'
  },
  (username, password, done) => {
  return db.one("SELECT * " +
    "FROM UserData " +
    "WHERE Email=$1", [username])
  .then((result)=> {
    return done(null, result);
  })
  .catch((err) => {
    return done(null, false, {message:'Wrong user name or password'});
  });
}));

module.exports = passport;
