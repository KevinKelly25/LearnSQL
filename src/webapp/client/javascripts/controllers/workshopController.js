/**
 * workshopController.js - LearnSQL
 *
 * Michael Torres
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the angularJS controller used for the student and teacher
 *  to be able to view log into their class database.
 */
/* eslint-disable no-param-reassign */


app.controller('workshopCtrl', ($scope, $http) => {
  $scope.initClasses = () => {
    $http.get('/workshop/getClasses')
      .success((data) => {
        $scope.classes = data;
      });
  };
});