/**
 * local.js - LearnSQL
 *
 * Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the passport.js authentication setup for the local strategy
 * used.
 */



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
  usernameField: 'username',
  passwordField: 'password'
  },
  (username, password, done) => {
  return db.one("SELECT * " +
    "FROM UserData " +
    "WHERE Username=$1", [username])
  .then((user)=> {
      console.log('getting here');
      console.log(user);
      if(!authHelpers.compareHashed(password, user.password)) {
          return done(null, false, {message: 'Wrong username or password'});
      } else {
         return done(null, user);
      }
  })
  .catch((err) => {
    return done(null, false, {message:'Wrong username or password'});
  });
}));

module.exports = passport;
