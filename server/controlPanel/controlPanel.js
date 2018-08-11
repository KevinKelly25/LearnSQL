const db = require('../db/ldb.js');
var uniqid = require('uniqid');

/**
 * This funciton creates a class database using a ClassDB template Database
 */
function createClass(req, res) {
	return handleErrors(req)
	.then(() => {
		var classid = req.body.name + '_' + uniqid(); //guarantee uniqueness
		db.task(t => {
        // this.ctx = task config + state context;
        return t.none('CREATE DATABASE $1~ WITH TEMPLATE classdb_template OWNER classdb', classid)
            .then(() => {
							return t.none('INSERT INTO class(classid, classname, password) VALUES(${id}, ${name}, ${password}) '
						, {
							id: classid,
							name: req.body.name,
							password: req.body.password
						})
						.then(() => {
							return t.none('INSERT INTO attends(username, classid, isteacher) VALUES(${name}, ${class}, ${isTeacher})'
							, {
								name: req.user.username,
								class: classid,
								isTeacher: true
								});
							});
					});
    })
    .then(events => {
        return res.status(200).json('Class Database Created Successfully');
    })
    .catch(error => {
        res.status(400).json({status: error});
    });
	})
}

/**
 * handles errors, for now only checks the length of the password
 * Also, set to a low number for testing purposes.
 */
function handleErrors(req) {
	console.log('handleErrors');
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
  createClass
};
