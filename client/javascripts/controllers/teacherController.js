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
app.controller('teacherCtrl', ($scope, $http) => {
  $scope.error = false;
  $scope.success = false;

  $scope.test = "hello it is working";

  $scope.init = () => {
    $scope.names = [
        { name: 'mike', color: 'blue'},
        { name: 'kevin', color: 'red'}
    ];
  }

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

});
