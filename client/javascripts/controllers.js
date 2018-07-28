/**
 * controller.js
 * This file contains the angularJS controllers that are used throughout the
 * LearnSQL website
 */

var app = angular.module('LearnSQL', []);

/**
 * The Question controller is supplied a user's query, $formData, and the correct
 * answer, $statement. The controller will route the user's query to a post
 * method that will return question database reponse to the supplied query.
 * Upon success of the user query it will use the same post method with the
 * correct query. Once successfully returned the two results will be compared
 * using a deep comparision. If they match a correct answer message will appear.
 * If results do not match or if any statement fails a wrong answer message will
 * appear
 */
 // TODO: test whether all deletes are needed or can be cleaned up
app.controller('Question', ($scope, $http) => {
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
 * This controller is used to dynamically display the navbar of the website
 * to show whether a user is logged in or not.
 */
app.controller('NavCtrl', ($scope, $http) => {
  $scope.register = () => {

  };
  $scope.Login = () => {
    $scope.test = "Works!!!";
  };
  $scope.Logout = () => {

  };
});

/**
 * This controller is used to display and use the login operations
 */
app.controller('LoginCtrl', ($scope, $http) => {
  $scope.form = 'login';
  $scope.error = false;
  $scope.errorMessage = 'Email or Password was incorrect';

  this.user = {
     email: '',
     password:''
  };
  $scope.register = () => {

  };
  $scope.login = () => {
    $scope.error = true;
    $scope.errorMessage = this.user;
  };
});
