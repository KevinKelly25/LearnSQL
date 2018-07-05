const passport = require('passport');
const LocalStrategy = require('passport-local').Strategy;
const authHelpers = require('./_helpers');

const init = require('./passport');


init();

passport.use(new LocalStrategy({
  usernameField: 'email',
  passwordField: 'pass'
  },
  (username, password, done) => {
  log.debug("Login process:", username);
  return db.one("SELECT * " +
    "FROM Users " +
    "WHERE Email=$1 AND Password=$2", [username, password])
  .then((result)=> {
    return done(null, result);
  })
  .catch((err) => {
    log.error("/login: " + err);
    return done(null, false, {message:'Wrong user name or password'});
  });
}));

module.exports = passport;
