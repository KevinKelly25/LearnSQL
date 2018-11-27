/**
 * studentController.js - LearnSQL
 *
 * Michael Torres, Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the angularJS controller used for the student functionality
 *  on the LearnSQL website
 */
/* eslint-disable no-param-reassign */


app.controller('studentCtrl', ($scope, $http, $window) => {
  $scope.class = {
    name: 'something',
  };

  $scope.init = () => {
    $http.get('/student/getClasses')
      .success((data) => {
        $scope.classes = data;
      });
  };


  $scope.joinClassFromPage = () => {
    $scope.error = false;
    $scope.success = true;
    $scope.message = 'Joining Class, Please Wait...';
    $scope.joinClass = {
      classID: $scope.classID,
      password: $scope.joinPassword,
    };
    $http.post('/student/joinClass', $scope.joinClass)
      .success(() => {
        $scope.message = 'Joined Class';
        $window.location.href = 'http://localhost:3000/views/controlPanels/studentClasses.html';
      })
      .error((error) => {
        $scope.error = true;
        $scope.success = false;
        $scope.message = error.status;
      });
  };


  $scope.goToClass = (classid) => {
    $http.get('/auth/check')
      .success((data) => {
        $scope.currentUser = data;
      });
    // Go to class page
    $window.location.href = 'http://localhost:3000/schema/#?username='
                            + `${$scope.currentUser.username}&classID=${classid}`;
  };
});
