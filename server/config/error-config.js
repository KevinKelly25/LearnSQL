/**
 * error-config.js - LearnSQL
 *
 * Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the server configuration related to error handling
 */
/* eslint-disable */
(function (errorConfig) {
  // *** error handling *** //

  errorConfig.init = function (app) {
    // catch 404 and forward to error handler
    app.use((req, res, next) => {
      const err = new Error('Not Found');
      err.status = 404;
      next(err);
    });

    // development error handler (will print stacktrace)
    if (app.get('env') === 'development') {
      app.use((err, req, res) => {
        res.status(err.status || 500).send({
          message: err.message,
          error: err,
        });
      });
    }

    // production error handler (no stacktraces leaked to user)
    app.use((err, req, res) => {
      res.status(err.status || 500).send({
        message: err.message,
        error: {},
      });
    });
  };
}(module.exports));
