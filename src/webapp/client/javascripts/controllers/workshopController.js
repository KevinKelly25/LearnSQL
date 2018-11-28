/**
 * workshopController.js - LearnSQL
 *
 * Michael Torres
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the angularJS controller used for users to be able to view
 *  log into their class database.
 */

/* eslint-disable no-param-reassign */


app.controller('workshopCtrl', ($scope, $http, $location) => {
  $scope.initClasses = () => {
    $http.get('/workshop/getClasses')
      .success((data) => {
        $scope.classes = data;
      });
  };

  $scope.initClass = () => {
    $scope.classInfo = {
      className: $location.search().class,
    };

    $scope.test = 'help';
    $http.post('/workshop/getClassInfo', $scope.classInfo)
      .success((data) => {
        $scope.classInfo = data;
      });
  };
});
