const passport = require('passport');
const db = require('../db/ldb.js');

module.exports = () => {

  passport.serializeUser((user, done) => {
    done(null, user.userid);
  });

  passport.deserializeUser((id, done)=>{
    db.one("SELECT userid, fullname, email, datejoined " +
           "FROM UserData " +
           "WHERE userid = $1", id)
    .then((user)=>{
      done(null, user);
    })
    .catch((err)=>{
      done(new Error(`User with the id ${id} does not exist`));
    })
  });
};
