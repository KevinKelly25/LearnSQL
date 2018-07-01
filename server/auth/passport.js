const passport = require('passport');

module.exports = () => {

  passport.serializeUser((user, done) => {
    done(null, user.id);
  });

  passport.deserializeUser((id, done) => {
		//add pg query to select user
		done(null,user.id)
  });

};
