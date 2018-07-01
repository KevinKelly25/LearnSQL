const express = require('express');
const router = express.Router();
const { Pool } = require('pg');
const path = require('path');
const connectionString = 'postgresql://postgres:password@localhost:5432/WCDB';

router.get('/', (req, res, next) => {
  res.sendFile(path.join(
    __dirname, '..', '..', 'client', 'views', 'index.html'));
});

router.post('/api/v1/WCDB', (req, res, next) => {
  const results = [];
  const pool = new Pool({
    connectionString: connectionString,
  })
  // Grab data from http request
  const data = {text: req.body.text, complete: false};
  // Get a Postgres client from the connection pool
  pool.connect((err, client, done) => {
    // Handle connection errors
    if(err) {
      done();
      console.log(err);
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
        var JSONobject = JSON.stringify(results);
        pool.end()
        return res.json(results);
      }
    })
  });
});

module.exports = router;
