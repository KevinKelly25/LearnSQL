/**
 * studentController.js - LearnSQL
 *
 * Michael Torres
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the angularJS controller used for the student functionality
 *  on the LearnSQL website
 */


var app = angular.module('LearnSQL');



app.controller('studentCtrl', ($scope, $http) => {
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
