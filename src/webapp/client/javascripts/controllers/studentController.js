/**
 * studentController.js - LearnSQL
 *
 * Christopher Innaco, Kevin Kelly, Michael Torres
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the angularJS controller used for the student functionality
 *  on the LearnSQL website
 */


app.controller('studentCtrl', ($scope, $http, $window) => {
  $scope.class = {
    name: '',
  };

  $scope.init = () => {
    $http.get('/student/getClasses')
      .success((data) => {
        data.forEach((element) => {
          element.classname = element.classname.toUpperCase();
        });
        $scope.classes = data;
      });

    $http.get('/auth/check')
      .success((data) => {
        $scope.currentUser = data;
      });
  };

  $scope.joinClassFromPage = () => {
    $scope.error = false;
    $scope.success = true;
    $scope.message = 'Joining Class . . .';
    $scope.joinClass = {
      classID: $scope.classID,
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

  $scope.goToClass = (classid) => {
    // Go to class page
    $window.location.href = 'http://localhost:3000/schema/#?username='
                            + `${$scope.currentUser.username}&classID=${classid}`;
  };
});
