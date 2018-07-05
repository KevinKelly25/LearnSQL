const passport = require('passport');

module.exports = () => {

  passport.serializeUser((user, done) => {
    done(null, user.UserID);
  });

  passport.deserializeUser((id, done)=>{
    log.debug("deserualize ", id);
    db.one("SELECT * FROM User " +
            "WHERE user_id = $1", [id])
    .then((user)=>{
      //log.debug("deserializeUser ", user);
      done(null, user);
    })
    .catch((err)=>{
      done(new Error(`User with the id ${id} does not exist`));
    })
  });

};
