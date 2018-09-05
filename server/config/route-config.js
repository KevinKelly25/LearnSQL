/**
 * route-config.js - LearnSQL
 *
 * Kevin Kelly, Michael Torres
 * Web Applications and Databases for Education (WADE)
 *
 * This file sets up the routes for the express router.
 */
/* eslint-disable */
(function (routeConfig) {
  routeConfig.init = function (app) {
    // *** routes *** //
    const routes = require('../routes/index');
    const authRoutes = require('../routes/auth');
    const adminRoutes = require('../routes/admin');
    const teacherRoutes = require('../routes/teacher');
    const studentRoutes = require('../routes/student');

    // *** register routes *** //
    app.use('/', routes);
    app.use('/auth', authRoutes);
    app.use('/admin', adminRoutes);
    app.use('/teacher', teacherRoutes);
    app.use('/student', studentRoutes);
  };
}(module.exports));
