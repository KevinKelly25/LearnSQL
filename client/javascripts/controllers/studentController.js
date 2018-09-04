/**
 * studentController.js - LearnSQL
 *
 * Michael Torres, Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the angularJS controller used for the student functionality
 *  on the LearnSQL website
 */


var app = angular.module('LearnSQL');



app.controller('studentCtrl', ($scope, $http, $window, $location) => {
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
  
  

  $scope.joinClassFromPage = () => {
    $scope.error = false;
    $scope.success = true;
    $scope.message = 'Joining Class, Please Wait...'
    $scope.joinClass = {
      classID: $scope.classID,
      password: $scope.joinPassword
    }
    $http.post('/student/joinClass', $scope.joinClass)
    .success((data) => {
      $scope.message = 'Joined Class';
      $window.location.href = 'http://localhost:3000/views/controlPanels/studentClasses.html';
    })
    .error((error) => {
      $scope.error = true;
      $scope.success = false;
      $scope.message = error.status;
    });
  }  
});
