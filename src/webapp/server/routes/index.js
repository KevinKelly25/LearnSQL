/**
 * index.js - LearnSQL
 *
 * Kevin Kelly, Michael Torres
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the route (URL handlers) and exports the router
 */

const express = require('express');

const router = express.Router();
const { Pool } = require('pg');
const path = require('path');
const nodemailer = require('nodemailer');

const connectionStringQuestions = 'postgresql://postgres:password@localhost:5432/questions';
const authHelpers = require('../auth/_helpers');
const tableHelpers = require('../controlPanel/tableControlPanel.js');
const logger = require('../logs/winston.js');



/**
 * This function is used to return http responses.
 *
 * @param {string} res The result object
 * @param {string} code The http status code
 * @param {string} statusMsg The message containing the status of the message
 * @return An http response with designated status code and attached
 */
function handleResponse(res, code, statusMsg) {
  res.status(code).json({ status: statusMsg });
}



// Basic get function for basic routing
router.get('/', (req, res) => {
  res.sendFile(path.join(
    __dirname, '..', '..', 'client', 'views', 'index.html',
  ));
});



/**
 * This method is given a possible sql query. It sends this query to the database
 *  If it is successful it will return the results in json. If an error occurs it
 *  will return the error statement/status
 */
// TODO: update to pg-promise
router.post('/api/v1/questions', (req, res) => {
  const results = [];
  const pool = new Pool({
    connectionString: connectionStringQuestions,
  });
  // Grab data from http request
  const data = { text: req.body.text, complete: false };
  // Get a Postgres client from the connection pool
  pool.connect((err, client, done) => {
    // Handle connection errors
    if (err) {
      done();
      return res.status(500).json({ success: false, data: err });
    }
    // SQL Query > Select Data
    client.query(data.text, (error, response) => {
      done();
      if (error) {
        return res.status(500).json({ success: false, data: err });
      }
      response.rows.forEach((row) => {
        results.push(row);
      });
      return res.json(results);
    });
    return res.status(200).json(results);
  });
});



/**
 * Sends a support ticket to the support email with given information provided
 *  by the user.
 *
 * @param {string} fullName The full name of the user sending in support request
 * @param {string} email The email the user wants support to contact
 * @param {string} clientMessage The message the user wants to be in the body
 *                                of the email
 * @return The http response of whether the email sent successfully
 */
router.post('/sendContact', (req, res) => {
  const output = `
        <h3>You have a new contact request</h3>
        <ul>
            <li>Full Name: ${req.body.fullName}</li>
            <li>Email: ${req.body.email}</li>
        </ul>
        <h3>Message</h3>
        <p>${req.body.clientMessage}</p>
    `;

  const transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com', // Host for outlook mail
    port: 587,
    secure: false, // True for 465, false for other ports
    auth: {
      user: 'learnsqltesting@gmail.com', // Email used for sending the message (will need to be changed)
      pass: process.env.EMAIL_PASSWORD,
    },
    tls: {
      // RejectUnauthorized:false will probably need to be changed for production because
      //  it can leave you vulnerable to MITM attack - secretly relays and alters the
      //  communication betwee two parties.
      rejectUnauthorized: false,
    },
  });

  // Setup email data with unicode symbols
  const mailOptions = {
    from: '"LearnSQL" <learnsqltesting@gmail.com>', // Sender address
    to: 'testacct123203@gmail.com', // List of receivers (email will need to be changed)
    subject: 'LearnSQL contact request', // Subject line
    text: 'Hello world?', // Plain text body
    html: output, // Html body
  };

  // Send mail with defined transport object
  transporter.sendMail(mailOptions, (error) => {
    if (error) {
      logger.error(`verification: \n${error}`);
      return new Error(error);
    }

    return res.status(200).json({ status: 'email sent' });
  });
});



/**
 * This route sends the user to tables.html. However, for it to work properly
 *  it must have two attached url parameters, username and classID. An example
 *  of this is:
 *  http://localhost:3000/table/#?username=teststu1&classID=testing1_1lvc01hojllf1r02
 */
router.get('/table/', authHelpers.loginRequired, (res) => {
  res.sendFile(path.join(
    __dirname, '..', '..', 'client', 'views', 'controlPanels', 'tables.html',
  ));
});



/**
 *  This route retrieves all tables/views for a user. Most functionality is in
 *   `tableControlPanel.js` getTables function.
 *
 * @param {string} username The username of the user who's tables are being
 *                           retrieved
 * @param {string} classID The classID of the class the tables are in
 */
router.post('/getTables', authHelpers.loginRequired, (req, res) => tableHelpers.getTables(req, res)
  .catch((err) => {
    handleResponse(res, 500, err);
  }));



/**
 * This route returns a table in JSON format when given a tableName. Most
 *  functionality is in `tableControlPanel.js` getTable function.
 *
 * @param {string} name The name of the table
 * @param {string} schema The schema the table is located in. Normally is the
 *                         username of the user who owns table
 * @param {string} classID The classID of the class the table is in
 * @return a table when given a tableName.
 */
router.post('/getTable', authHelpers.loginRequired, (req, res) => tableHelpers.getTable(req, res)
  .catch((err) => {
    handleResponse(res, 500, err);
  }));



module.exports = router;
