/**
 * profileController.js - LearnSQL
 *
 * Christopher Innaco
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the angularJS controller used for the user profile page functionality
 *  on the LearnSQL website
 */

var app = angular.module('LearnSQL');

/**
  * This controller dynamically updates the HTML view for the profile.html page.
*/
app.controller('ProfileCtrl', ($scope, $http) => {
  $scope.showInstructorRow = false;
  $scope.showAdminRow = false;
  $scope.error = false;
  $scope.success = false;

  $http.get('/auth/check')
    .success((data) => {

      // Upon loading the page, populate the table with the user information
      //  from the passport.deserializeUser() function.
      $scope.userName = data.username;
      $scope.fullName = data.fullname;
      $scope.email = data.email;
      $scope.dateJoined = convertDate(data.datejoined);

      if(data.isteacher)
      {
        $scope.showInstructorRow = true;
      }

      if(data.isadmin)
      {
        $scope.showAdminRow = true;
      }

    })
    .error((error) => {
      $scope.error = "Unable to retrieve user information";
    });

  function convertDate(inputDateString){
    var date = new Date(inputDateString);
    return date.getMonth()+1 + "/" + date.getDate() + "/" + date.getFullYear();
  }

  $scope.editInformation = () => {

    // Confirm new usernames match
    if($scope.newUsername != $scope.newUsername_Confirm)
    {
      $scope.success = false;
      $scope.error = true;
      $scope.message = 'Usernames do not match';
      return;
    }
    /*else
    {
      $scope.success = true;
      $scope.error = false;
      $scope.message = 'Usernames match';
     
    }*/

    $scope.newUsername_Info = {

      newUsername: $scope.newUsername,
      oldUsername: $scope.userName

    };


    // Use the `/editInformation` route to run the query which inserts new values into the database
    $http.post('/editInformation', $scope.newUsername_Info)
    .success((data) => {
      $scope.success = true;
      $scope.message = 'User information updated sucessfully';

      $scope.updatedUser = {

        userName: $scope.newUsername,
        password: $scope.passwordPrompt
      };

      // If the new username is updated in the table, automatically perform the login process
      $http.post('/auth/login', $scope.updatedUser)
      .success((data) => {
      $window.location.href = 'http://localhost:3000/views/account/profile.html';
      })
      .error((error) => {
      $scope.error = true;
      $scope.message = error.status;
      });

    })
    .error((error) => {
      $scope.success = false;
      $scope.error = true;
      $scope.message = error.status;
    });

  }

});