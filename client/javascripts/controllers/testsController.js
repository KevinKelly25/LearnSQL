/**
 * testController.js - LearnSQL
 *
 * Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the angularJS controller used for testing the LearnSQL
 *  website
 */


var app = angular.module('LearnSQL');

/**
 * This controller is used for the admin control panel to add classes
 */
app.controller('TestsCtrl', ($scope, $http) => {
  $scope.addDropClassTestStatus = 'Unchecked';
  $scope.successTestStatus = 'Unchecked';
  $scope.failTestStatus = 'Unchecked';




  /**
   * This function calls the /admin/addClass post method to create ClassDB databases
   *  and updates the associated LearnSQL tables. While processing a message
   *  appears to let the user know to wait.
   */
  $scope.testAddDropClass = () => {
		this.class = {
	     name: null,
	     password: null
	  };
		// TODO: how to make synchronous or should i just move this to a normal javascript
		$scope.addDropClassTestStatus = 'Testing';
		this.class.name = 'Create_test';
		this.class.password = 'test';
    $http.post('/admin/addClass', this.class)
    .success((data) => {
      $scope.addDropClassTestStatus = data.status;
    })
    .error((error) => {
      $scope.addDropClassTestStatus = error.status;
    });

		$http.post('/admin/dropClass', this.class)
		.success((data) => {
			$scope.addDropClassTestStatus = data.status;
		})
		.error((error) => {
			$scope.addDropClassTestStatus = error.status;
		});

		$http.get('/auth/check')
    .success((data) => {
      $scope.addDropClassTestStatus = '2';
    })
    .error((error) => {
      //error
    });
  };



  $scope.testSuccess = () => {
    $scope.successTestStatus = 'Passed';
  };



  $scope.testFail = () => {
    $scope.failTestStatus = 'Failed: code 1';
  };

});
