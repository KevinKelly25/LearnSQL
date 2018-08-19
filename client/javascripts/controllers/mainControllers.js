/**
 * mainControllers.js - LearnSQL
 *
 * Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the Main angularJS controllers that are used throughout the
 * LearnSQL website
 */

var app = angular.module('LearnSQL', []);


/**
 * This controller is used to dynamically display the navbar of the website
 *  to show whether a user is logged in or not.
 */
app.controller('NavCtrl', ($scope, $http) => {
  $scope.currentUser = {};
  $scope.message = 'message';

  /**
   * This function is used to log the user out. The functionality is primarily
   *  in the REST api /auth/logout function. If logout is sucessful init() is called
   *  which will refresh the values on the page. This is done once the currentUser
   *  is updated.
   */
  $scope.logout = () => {
    $http.get('/auth/logout')
    .success((data) => {
      $scope.init()
    })
    .error((error) => {
      //could not log out
    });
  };

  /**
   * This function is used to check the current user, if any. If there is a user
   *  the current user will be updated with its user information. The functionality
   *  is primarily in the REST api /auth/check function.
   */
  $scope.init = () => {
    $http.get('/auth/check')
    .success((data) => {
      $scope.currentUser = data;
    })
    .error((error) => {
      //error
    });
  }
});
