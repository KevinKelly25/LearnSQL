const db = require('../db/ldb.js');
var uniqid = require('uniqid');

/**
 * This funciton creates a class database using a ClassDB template Database
 */
function createClass(req, res) {
	db.none('CREATE DATABASE ${name} WITH TEMPLATE classdb_template OWNER classdb '
	, {
		name: req.body.name + '/' + uniqid();//garantee uniqueness
	})
	.then(() => {
			return res.status(200).json('Class Created Successfully');
	})
	.catch(error => {
			res.status(400).json({status: error});
	})
}


module.exports = {
  createClass
};
