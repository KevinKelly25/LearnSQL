/**
 * teacherController.js - LearnSQL
 *
 * Michael Torres, Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the angularJS controller used for the teacher functionality
 *  on the LearnSQL website
 */


var app = angular.module('LearnSQL');


/**
 * This controller is used for the teacher control panel to add classes
 */
app.controller('studentCtrl', ($scope, $http, $location, $window) => {
  $scope.class = {
    name: 'something'
  };

  $scope.init = () => {
    $http.get('/student/getClasses')
    .success((data) => {
      $scope.classes = data;
    })
    .error((error) => {
      //do something if encounters an error
    });
  }
});
