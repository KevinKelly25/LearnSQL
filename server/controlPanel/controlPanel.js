const db = require('../db/ldb.js');
var uniqid = require('uniqid');

/**
 * This funciton creates a class database using a ClassDB template Database
 */
function createClass(req, res) {
	var classname = req.body.name + '/' + uniqid(); //guarantee uniqueness
	db.none('CREATE DATABASE ${name} WITH TEMPLATE classdb_template OWNER classdb '
	, {
		name: classname
	})
	.then(() => {
			addClassToDB(classname, req.body.name, req.body.password)
	.then(() => {
			addInstructorToDB(req.user.username, classname)
	.then(() => {
			res.status(200).json({status: 'Class Database Created Successfully'});
	})
	.catch(error => {
			res.status(400).json({status: error});
	})
}

function addInstructorToDB(username, classid) {
	db.none('INSERT INTO attends(username, classid, isteacher) VALUES(${name}, ${class}, ${isTeacher})'
	, {
		name: username,
		class: classid,
		isTeacher: true
	})
	.then(() => {
			return res.status(200).json('Instructor Added Successfully');
	})
	.catch(error => {
			res.status(400).json({status: 'Could not add instructor to DB'});
	})
}

function addClassToDB(username, classid, password) {
	db.none('INSERT INTO class(classid, classname, password) VALUES(${id}, ${name}, ${password}) '
	, {
		id: classid,
		name: classname,
		password: password
	})
	.then(() => {
			return res.status(200).json('Class Added Successfully');
	})
	.catch(error => {
			res.status(400).json({status: 'Could not add Class to DB'});
	})
}


module.exports = {
  createClass
};
