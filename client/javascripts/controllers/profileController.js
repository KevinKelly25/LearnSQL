/**
 * profileController.js - LearnSQL
 *
 * Christopher Innaco
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the angularJS controller used for the user profile page functionality
 *  on the LearnSQL website
 */


/**
  * This controller dynamically updates the HTML view for the profile.html page.
*/
app.controller('ProfileCtrl', ($scope, $http) => {
  $scope.showInstructorRow = false;
  $scope.showAdminRow = false;
  $scope.error = false;
  $scope.success = false;


  // Converts the date from postgres format to readable format
  function convertDate(inputDateString) {
    const date = new Date(inputDateString);
    return `${date.getMonth() + 1}/${date.getDate()}/${date.getFullYear()}`;
  }



  // Function activates upon loading page obtaining current user information
  $http.get('/auth/check')
    .success((data) => {
      // Upon loading the page, populate the table with the user information
      //  from the passport.deserializeUser() function.
      $scope.userName = data.username;
      $scope.fullName = data.fullname;
      $scope.email = data.email;
      $scope.dateJoined = convertDate(data.datejoined);

      if (data.isteacher) {
        $scope.showInstructorRow = true;
      }

      if (data.isadmin) {
        $scope.showAdminRow = true;
      }
    })
    .error(() => {
      $scope.error = 'Unable to retrieve user information';
    });
});
