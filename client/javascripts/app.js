angular.module('nodeQuestion', [])
.controller('Question', ($scope, $http) => {
  $scope.formData = {};
  $scope.answerData = {};
  $scope.correctData = {};
  $scope.statement = {};
  $scope.statementInHTML = {};
  $scope.answer = '';
  $scope.backgroundColor = 'black';
  $scope.answerQuestion = () => {
    $scope.statement = {"text":$scope.statementInHTML};
    $http.post('/api/v1/WCDB', $scope.formData)//The submitted answer
    .success((data1) => {
      delete $scope.formData;
      $scope.answerData = data1;
      console.log(data1);
      $http.post('/api/v1/WCDB', $scope.statement)//the correct answer
      .success((data2) => {
        delete $scope.statement;
        $scope.correctData = data2;
        $scope.answer = $scope.answerData;
        console.log(data2);
        if (angular.equals($scope.answerData,$scope.correctData)) {//if the correct answer and submitted answer match
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
        console.log('Error: ' + error);
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
      console.log('Error: ' + error);
      $scope.answer = "Your Answer is Incorrect";
      $scope.backgroundColor = 'red';
      delete $scope.statement;
      delete $scope.answerData;
      delete $scope.correctData;
      return;
    });
  };
});
