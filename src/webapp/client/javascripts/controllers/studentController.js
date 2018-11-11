/**
 * studentController.js - LearnSQL
 *
 * Christopher Innaco, Kevin Kelly, Michael Torres
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

  // Converts the date from PostgreSQL format to readable format
  function convertDate(inputDateString) {
    const date = new Date(inputDateString);
    return `${date.getMonth() + 1}/${date.getDate()}/${date.getFullYear()}`;
  }

  $scope.init = () => {
    $http.get('/student/getClasses')
      .success((data) => {       
        data.forEach((element) => { 
          element.classname = element.classname.toUpperCase();
          element.startdate = convertDate(element.startdate);
          element.enddate =  convertDate(element.enddate);
        });
        $scope.classes = data;
      });
  };


  $scope.joinClassFromPage = () => {
    $scope.error = false;
    $scope.success = true;
    $scope.message = 'Joining Class . . .';
    $scope.joinClass = {
      className: $scope.className,
      classSection: $scope.classSection,
      startDate: $scope.startDate,
      classPassword: $scope.classPassword,
    };
    $http.post('/student/joinClass', $scope.joinClass)
      .success(() => {
        $scope.message = 'Successfully enrolled in class';
        $window.location.href = 'http://localhost:3000/views/controlPanels/studentClasses.html';
      })
      .error((error) => {
        $scope.error = true;
        $scope.success = false;
        $scope.message = error.status;
      });
  };
});
