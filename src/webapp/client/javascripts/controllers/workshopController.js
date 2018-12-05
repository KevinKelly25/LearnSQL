/**
 * workshopController.js - LearnSQL
 *
 * Michael Torres
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the AngularJS controller used for users to be able to view
 *  log into their class database.
 */

/* eslint-disable no-param-reassign */


app.controller('workshopCtrl', ($scope, $http, $location) => {
  $scope.initClasses = () => {
    $http.get('/workshop/getClasses')
      .success((data) => {
        data.forEach((element) => {
          element.classname = element.classname.toUpperCase();
        });
        $scope.classes = data;
      });
  };

  $scope.initClass = () => {
    $http.get('/workshop/getClasses')
      .success(() => {
        // Middleware will utilize the data returned from this POST request
      });

    $scope.className = ($location.search().class).toUpperCase();
  };
});