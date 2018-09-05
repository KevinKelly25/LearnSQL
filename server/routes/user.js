const express = require('express');

const router = express.Router();

const authHelpers = require('../auth/_helpers');

// TODO: define and explain route better as this is currently unused
router.get('/user', authHelpers.loginRequired, (req, res, next) => {
  handleResponse(res, 200, 'success');
});

// TODO: define and explain route better as this is currently unused
router.get('/admin', authHelpers.adminRequired, (req, res, next) => {
  handleResponse(res, 200, 'success');
});

// adds a status code and message to response
function handleResponse(res, code, statusMsg) {
  res.status(code).json({ status: statusMsg });
}

module.exports = router;
