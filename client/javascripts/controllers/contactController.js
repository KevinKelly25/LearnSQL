/**
 * contactController.js - LearnSQL
 *
 * Kevin Kelly, Michael Torres
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the angularJS controller that is for the contact form
 */


 /**
  * This controller is used to display success and error messges
  * in the contact form
  */
 app.controller('ContactCtrl', ($scope, $http) => {
   $scope.error = false;
   $scope.success = false;

   //client information
   this.user = {
      fullName: null,
      email: null,
      clientMessage: null
   };

   /**
    * This function takes in user information only, (their full name, email, and their message)
    * and check to see if any of the input fields are missing (left empty).
    */

   $scope.submit = () => {
     $scope.error = false;
     $scope.success = true;
     $scope.msg = 'email being sent, please wait...';

     this.user.fullName = $scope.fullName;
     this.user.email = $scope.email;
     this.user.clientMessage = $scope.clientMessage;

     // if user does not enter their name
     if(!$scope.fullName)
     {
       $scope.error = true;
       $scope.success = false;
       $scope.msg = 'first name missing';
     }

     // if user does not enter their email
     if(!$scope.email)
     {
       $scope.error = true;
       $scope.success = false;
       $scope.msg = 'email missing';
     }

     // if user does not enter the message to be delivered
     if(!$scope.clientMessage)
     {
       $scope.error = true;
       $scope.success = false;
       $scope.msg = 'message content missing';
     }


     $http.post('/sendContact', this.user)
     .success((data) => {
       $scope.success = true;
       $scope.msg = data.status;
     })
     .error((error) => {
       $scope.error = true;
       $scope.success = false;
       $scope.msg = 'error';
     });

   };
 });
