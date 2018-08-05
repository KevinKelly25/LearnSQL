const express = require('express');
const router = express.Router();

const authHelpers = require('../auth/_helpers');


/**
 * This method create user using a helper function. If an error is encountered
 * an error status code and message is returned
 */
router.post('/addClass', authHelpers.adminRequired, (req, res, next)  => {
  return authHelpers.createUser(req, res)
  .catch((err) => {
    handleResponse(res, 500, 'error');
  });
});

module.exports = router;
