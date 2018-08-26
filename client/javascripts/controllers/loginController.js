/**
 * loginController.js - LearnSQL
 *
 * Kevin Kelly, Michael Torres
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the angularJS controllers that are used throughout the
 * LearnSQL website
 */



/**
 * This controller is used to display and use the login operations
 */
app.controller('LoginCtrl', ($scope, $http, $location, $window) => {
  $scope.form = 'login';
  $scope.error = false;
  $scope.success = false;

  //user information
  this.user = {
     username: null,
     email: null,
     password: null,
     fullName: null
  };



  /**
   * This function takes user information into the controller. First email syntax validation
   *  check is done, which checks that it fits into the general format of all emails.
   *  Otherwise, an error message is displayed because email failed the check. If Passwords
   *  do not match then an error message is displayed. The post method '/auth/register'
   *  is used to register the user. Upon sucess a sucess message is displayed.
   *  If register method fails an error message is displayed showing the error
   */
  $scope.register = () => {
    $scope.error = false;
    $scope.success = true;
    $scope.message = 'User Being Created, Please Wait...'
    // TODO: do these work directly in the html page?
    this.user.email = $scope.email;
    this.user.password = $scope.password;
    this.user.fullName = $scope.fullName;
    this.user.username = $scope.username;
    //if email was entered incorrectly or not entered
    if (!$scope.email)
    {
      $scope.error = true;
      $scope.message = 'Email not valid';
    }
    //if passwords do not match display error
    else if ($scope.password != $scope.password2)
    {
      $scope.error = true;
      $scope.message = 'Passwords do not match';
    } else
    {
      $http.post('/auth/register', this.user)
      .success((data) => {
        $scope.success = true;
        $scope.message = data;
      })
      .error((error) => {
        $scope.error = true;
        $scope.message = error.status;
      });
    }
  };

  /**
   * This function takes user information into the controller. First email validation
   *  check is done first. Error message is displayed if email failed. If Passwords
   *  do not match then an error message is displayed. The post method '/auth/register'
   *  is used to register the user. Upon sucess a sucess message is displayed.
   *  If register method fails an error message is displayed showing the error
   */
  $scope.login = () => {
    $scope.error = false;
    $scope.success = false;
    this.user.username = $scope.username;
    this.user.password = $scope.password;
    $http.post('/auth/login', this.user)
    .success((data) => {
      $window.location.href = 'http://localhost:3000';
    })
    .error((error) => {
      $scope.error = true;
      $scope.message = error.status;
    });
  };



  $scope.forgotPassword = () => {
    $scope.error = false;
    $scope.success = true;
    $scope.message = 'Sending Email, Please Wait...';
    $scope.email = {
        email: $scope.forgotEmail
    };
    $http.post('/auth/forgotPasswordEmail', $scope.email)
    .success((data) => {
        $scope.error = false;
        $scope.success = true;
        $scope.success = data;
    })
    .error((error) => {
      $scope.success = false;
      $scope.error = true;
      $scope.message = error;
    });
  };



  /**
   * This function takes user information into the controller. First email syntax validation
   *  check is done, which checks that it fits into the general format of all emails.
   *  Otherwise, an error message is displayed because email failed the check. If Passwords
   *  do not match then an error message is displayed. The post method '/auth/register'
   *  is used to register the user. Upon sucess a sucess message is displayed.
   *  If register method fails an error message is displayed showing the error
   */
  $scope.resetPassword = () => {
    $scope.error = false;
    $scope.success = true;
    $scope.message = 'Reseting Password, please wait...'
    //if passwords do not match display error
    if ($scope.password1 != $scope.password2)
    {
      $scope.error = true;
      $scope.message = 'Passwords do not match';
    } else
    {
      $scope.parameters = {
          token: $location.search().token,
          password: $scope.password1,
          username: $scope.username
      };
      $http.post('/auth/resetPassword', $scope.parameters)
      .success((data) => {
        $scope.message = 'Password Reset';
      })
      .error((error) => {
        $scope.error = true;
        $scope.success = false;
        $scope.message = error;
      });
  }
  };

});
