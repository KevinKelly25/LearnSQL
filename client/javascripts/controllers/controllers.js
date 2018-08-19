/**
 * controllers.js - LearnSQL
 *
 * Kevin Kelly, Michael Torres
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the angularJS controllers that are used throughout the
 * LearnSQL website
 */


var app = angular.module('LearnSQL');

/**
 * The Question controller is used to create dynamic questions for the user using
 *  the function answerQuestion
 */
 // TODO: test whether all deletes are needed or can be cleaned up
app.controller('Question', ($scope, $http) => {

  /**
   * The answeQuestion function is passed a user's query, $formData, and the correct
   *  answer, $statement. The controller will route the user's query to a post
   *  method that will return question database reponse to the supplied query.
   *  Upon success of the user query it will use the same post method with the
   *  correct query. Once successfully returned the two results will be compared
   *  using a deep comparision. If they match a correct answer message will appear.
   *  If results do not match or if any statement fails a wrong answer message will
   *  appear
   */
  $scope.answerQuestion = () => {
    $scope.statement = {"text":$scope.statementInHTML};
    $http.post('/api/v1/questions', $scope.formData)//The submitted answer
    .success((data1) => {
      delete $scope.formData;
      $scope.answerData = data1;
      $http.post('/api/v1/questions', $scope.statement)//the correct answer
      .success((data2) => {
        delete $scope.statement;
        $scope.correctData = data2;
        $scope.answer = $scope.answerData;
        //if the correct answer and submitted answer match
        if (angular.equals($scope.answerData,$scope.correctData)) {
          $scope.answer = 'Your Answer Is Correct';
          $scope.backgroundColor = 'green';
          delete $scope.answerData;
          delete $scope.correctData;
        } else {
          $scope.answer = 'Your Answer Is Incorrect';
          $scope.backgroundColor = 'red';
          delete $scope.answerData;
          delete $scope.correctData;
        }
      })
      //if the correct answer has an error processing
      .error((error) => {
        $scope.answer = "Your Answer is Incorrect";
        $scope.backgroundColor = 'red';
        delete $scope.statement;
        delete $scope.answerData;
        delete $scope.correctData;
        return;
      });
    })
    //if the submitted answer conneciton fails
    .error((error) => {
      $scope.answer = "Your Answer is Incorrect";
      $scope.backgroundColor = 'red';
      delete $scope.statement;
      delete $scope.answerData;
      delete $scope.correctData;
      return;
    });
  };
});

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
    $scope.success = false;
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
      $scope.message = error;
    });
  };

  // TODO: add functionality
  $scope.forgotPassword = () => {

  };

});


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


    $http.post('/send', this.user)
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
