/**
 * adminController.js - LearnSQL
 *
 * Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the angularJS controller used for the admin functionality
 *  on the LearnSQL website
 */


var app = angular.module('LearnSQL');


/**
 * This controller is used for the admin control panel to add classes
 */
app.controller('AdminCtrl', ($scope, $http, $location, $window) => {
  $scope.form = 'default';
  $scope.error = false;
  $scope.success = false;

  //class information
  this.class = {
     name: null,
     password: null
  };

  /**
   * This function calls the /admin/addClass post method to create ClassDB databases
   *  and updates the associated LearnSQL tables. While processing a message
   *  appears to let the user know to wait.
   */
  $scope.addClass = () => {
    $scope.error = false;
    this.class.name = $scope.class;
    this.class.password = $scope.password;
    $scope.success = true;
    $scope.message = 'Database Being Created, Please Wait';

    //make sure that is a valid name
    var regex = new RegExp("^[a-zA-Z0-9_]*$");
    if (regex.test(this.class.name))
    {
      $http.post('/admin/addClass', this.class)
      .success((data) => {
        $scope.success = true;
        $scope.message = 'Database Successfully Created';
      })
      .error((error) => {
        $scope.success = false;
        $scope.error = true;
        $scope.message = error.status;
      });
    } else
    {
      $scope.message = 'Invalid Characters Detected! Please Use only the following ' +
                       'characters: A-Z, 0-9, - only (case insensitive)';
    }
  };


  /**
   * This function calls the /admin/addClass post method to create ClassDB databases
   *  and updates the associated LearnSQL tables. While processing a message
   *  appears to let the user know to wait.
   */
  $scope.selectClass = () => {
    $scope.error = false;
    this.class.name = $scope.class;
    this.class.password = $scope.password;
    $scope.success = true;
    $scope.message = 'Data being searched';
    $http.post('/teacher/selectClass', this.class)
    .success((data) => {
      $scope.success = true;
      $scope.message = 'Database Successfully Created';
    })
    .error((error) => {
      $scope.success = false;
      $scope.error = true;
      $scope.message = error.status;
    });
  };
});
