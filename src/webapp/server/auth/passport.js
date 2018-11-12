/**
 * local.js - LearnSQL
 *
 * Kevin Kelly, Michael Torres
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the passport.js serialization and deserialization
 * of the user.
 */


const passport = require('passport');
const db = require('../db/ldb.js');

module.exports = () => {
  /**
   * Uses the built in Passport.js module functionality to serialize the UserID
   * to the session.
   */
  passport.serializeUser((user, done) => {
    done(null, user.username);
  });

  /**
   * Uses the built in Passport.js module functionality to deserialize the UserID
   *  from the session. The UserID is then used to return userid, fullname, email
   *  and datejoined from the database using pg-promise. It then returns the user
   *  object created from that query. If there is an error it returns an error message
   *  displaying the id that failed.
   */
  passport.deserializeUser((id, done) => {
    db.one('SELECT username, fullname, email, datejoined, isAdmin, isTeacher, isstudent '
           + 'FROM LearnSQL.UserData '
           + 'WHERE username = $1', id)
      .then((user) => {
        done(null, user);
      })
      .catch(() => {
        done(new Error(`User with the id ${id} does not exist`));
      });
  });
};
