/**
 * controlPanel.js - LearnSQL
 *
 * Christopher Innaco
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the functions for user control panel (user profile page)
 */


const ldb = require('../db/ldb.js');
const dbCreator = require('../db/cdb.js');
const logger = require('../logs/winston.js');

function editInformation(req, res) {
  return new Promise((resolve, reject) => {
		ldb.none('UPDATE userdata ' +
				     'SET username = $1' +
				     'WHERE username = $2', [req.body.newUsername, req.body.oldUsername])
          .then((result) => {
            console.log("RESULT: " + result);
						resolve();
						//db.$pool.end(); //Closes the connection to the database. IMPORTANT!!
						return res.status(200).json('Information updated successfully');
					})
          .catch((error)=> {
            console.log("POST ERROR: " + error);
						reject({
							message: 'Unable to update information'
						});
						return;
					});
				})   
};

function confirmPassword(req, res) {
  return new Promise((resolve, reject) => {
		ldb.one('SELECT password ' +
				     'FROM userdata' +
				     'WHERE username = $1', [req.body.newUsername])
          .then((result) => {
            console.log("RESULT: " + result);
						resolve();
						//db.$pool.end(); //Closes the connection to the database. IMPORTANT!!
						return res.status(200).json('Information updated successfully');
					})
          .catch((error)=> {
            console.log("POST ERROR: " + error);
						reject({
							message: 'Unable to update information'
						});
						return;
					});
				})   
};

module.exports = {
  editInformation,
  confirmPassword
};
