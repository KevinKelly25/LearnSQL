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
 * This controller is used for the admin to test the LearnSQL website
 */
app.controller('TestsCtrl', ($scope, $http, $window) => {
  $scope.addDropClassTestStatus = 'Unchecked';
  $scope.successTestStatus = 'Unchecked';
  $scope.failTestStatus = 'Unchecked';




  /**
   * This function calls the /admin/addClass post method to create ClassDB databases
   *  and updates the associated LearnSQL tables. While processing a message
   *  appears to let the user know to wait.
   */
  $scope.testAddDropClass = () => {
		// TODO: how to make synchronous or should i just move this to a normal javascript
		$scope.addDropClassTestStatus = 'Testing';

		//Counts the number of successful tests. If number of tests = count then all
		// tests have passed
		$scope.count = 0;
		$scope.testStats = {
			numberOfTests: 3,
			numberOfExpectedLogs: 1
		}

		$http.post('/admin/testLogWarning', $scope.testStats)
		.error((error) => {
			$scope.addDropClassTestStatus = error;
		});


		//Tests normal contitions of add and drop class http post methods
		$scope.class1 = {
	     name: 'create_test1',
	     password: 'test'
	  };
    $http.post('/admin/addClass', $scope.class1)
    .success((data) => {
      $http.post('/admin/dropClass', $scope.class1)
			.success((data) => {
				$scope.count += 1;
				if ($scope.count == $scope.numberOfTests)
					return $scope.addDropClassTestStatus = 'Passed';
			}).error((error) => {
				return $scope.addDropClassTestStatus = 'Fail Code 2';
			});
    })
		.error((error) => {
			$scope.addDropClassTestStatus = 'Fail Code 1';
			if (error.status == 'Class Already Exists With That Name'){
				$window.alert('Database Needs To Be Cleaned, Test databases are present' +
				 'and should not be');
			}
			return;
		});

		//Tests normal contitions of add and drop class http post methods, tests
		// creating and droping multiple databases at once
		$scope.class2 = {
			 name: 'create_test2',
			 password: 'test'
		};
		$http.post('/admin/addClass', $scope.class2)
		.success((data) => {
			$http.post('/admin/dropClass', $scope.class2)
			.success((data) => {
				$scope.count += 1;
				if ($scope.count == $scope.numberOfTests)
					return $scope.addDropClassTestStatus = 'Passed';
			}).error((error) => {
				return $scope.addDropClassTestStatus = 'Fail Code 4';
			});
		})
		.error((error) => {
			$scope.addDropClassTestStatus = 'Fail Code 3';
			if (error.status == 'Class Already Exists With That Name'){
				$window.alert('Database Needs To Be Cleaned, Test databases are present' +
				 'and should not be');
			}
			return;
		});


		// tests that addClass will reject another class with same ClassName
		$scope.class3 = {
			 name: 'create_test3',
			 password: 'test'
		};
		$http.post('/admin/addClass', $scope.class3)
		.success((data) => {
			//This should fail
			$http.post('/admin/addClass', $scope.class3)
			.success((data) => {
				return $scope.addDropClassTestStatus = 'Fail Code 5';
			}).error((error) => {
				$http.post('/admin/dropClass', $scope.class3)
				.success((data) => {
					$scope.count += 1;
					if ($scope.count == $scope.numberOfTests)
						return $scope.addDropClassTestStatus = 'Passed';
				})
			});
		})
		.error((error) => {
			$scope.addDropClassTestStatus = 'Fail Code 6';
			if (error.status == 'Class Already Exists With That Name'){
				$window.alert('Database Needs To Be Cleaned, Test databases are present' +
				 'and should not be');
			}
			return;
		});

  };



  $scope.testSuccess = () => {
    $scope.successTestStatus = 'Passed';
  };



  $scope.testFail = () => {
    $scope.failTestStatus = 'Failed: code 1';
  };

});
