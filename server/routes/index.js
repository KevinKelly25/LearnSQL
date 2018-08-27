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
const connectionStringLearnsql = 'postgresql://postgres:password@localhost:5432/learnsql';

//Basic get function for basic routing
router.get('/', (req, res, next) => {
  res.sendFile(path.join(
    __dirname, '..', '..', 'client', 'views', 'index.html'));
});

/**
 * This method is given a possible sql query. It sends this query to the database
 * If it is sucessful it will return the results in json. If an error occures it
 * will return the error statement/status
 */
 // TODO: update to pg-promise
router.post('/api/v1/questions', (req, res, next) => {
  const results = [];
  const pool = new Pool({
    connectionString: connectionStringQuestions,
  })
  // Grab data from http request
  const data = {text: req.body.text, complete: false};
  // Get a Postgres client from the connection pool
  pool.connect((err, client, done) => {
    // Handle connection errors
    if(err) {
      done();
      return res.status(500).json({success: false, data: err});
    }
    // SQL Query > Select Data
    var query = client.query(data.text, (err, response) => {
      done()
      if (err) {
        return res.status(500).json({success: false, data: err});
      } else {
        response.rows.forEach(row =>{
          results.push(row)
        })
        return res.json(results);
      }
    })
  });
});

router.post('/sendContact', (req, res, next) => {
  const output = `
        <h3>You have a new contact request</h3>
        <ul>
            <li>Full Name: ${req.body.fullName}</li>
            <li>Email: ${req.body.email}</li>
        </ul>
        <h3>Message</h3>
        <p>${req.body.clientMessage}</p>
    `;

  let transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com', // host for outlook mail
    port: 587,
    secure: false, // true for 465, false for other ports
    auth: {
        user: 'learnsqltesting@gmail.com', // email used for sending the message (will need to be changed)
        pass: 'testing123!'
    },
    tls:{
        // rejectUnauthorized:false will probably need to be changed for production because
        // it can leave you vulnerable to MITM attack - secretly relays and alters the
        // communication betwee two parties.
        rejectUnauthorized:false
    }
  });

  // setup email data with unicode symbols
  let mailOptions = {
      from: '"LearnSQL" <learnsqltesting@gmail.com>', // sender address
      to: 'testacct123203@gmail.com', // list of receivers (email will need to be changed)
      subject: 'LearnSQL contact request', // Subject line
      text: 'Hello world?', // plain text body
      html: output // html body
  };

  // send mail with defined transport object
  transporter.sendMail(mailOptions, (error, info) => {
      if (error) {
          return console.log(error);
      }
      console.log('Message sent: %s', info.messageId);
      console.log('Preview URL: %s', nodemailer.getTestMessageUrl(info));

      return res.status(200).json({status: 'email sent'});
  });
});

module.exports = router;
