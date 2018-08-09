const express = require('express');
const router = express.Router();
const { Pool } = require('pg');
const path = require('path');
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

module.exports = router;
