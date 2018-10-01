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
const db = require('../db/ldb.js');

init();


/**
 * This function sets up the local strategy for the passport.js module. usernameField
 *  and passwordField are set to the database equivalent of their names.
 *  Using pg-promise the query returns userdata if there is a matching userID
 */
passport.use(new LocalStrategy({
  usernameField: 'username',
  passwordField: 'password',
},
(username, password, done) => db.one('SELECT * '
                                   + 'FROM UserData '
                                   + 'WHERE Username=$1', [username])
  .then((user) => {
    if (!authHelpers.compareHashed(password, user.password)) {
      return done(null, false, { message: 'Wrong username or password' });
    }
    return done(null, user);
  })
  .catch(() => done(null, false, { message: 'Wrong username or password' }))));

module.exports = passport;
