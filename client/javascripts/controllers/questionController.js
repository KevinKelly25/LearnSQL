/**
 * questionController.js - LearnSQL
 *
 * Kevin Kelly, Michael Torres
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the angularJS controller that is for user questions
 */


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
    $scope.statement = { text: $scope.statementInHTML };
    $http.post('/api/v1/questions', $scope.formData)// The submitted answer
      .success((data1) => {
        delete $scope.formData;
        $scope.answerData = data1;
        $http.post('/api/v1/questions', $scope.statement)// the correct answer
          .success((data2) => {
            delete $scope.statement;
            $scope.correctData = data2;
            $scope.answer = $scope.answerData;
            // if the correct answer and submitted answer match
            if (angular.equals($scope.answerData, $scope.correctData)) {
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
        // if the correct answer has an error processing
          .error(() => {
            $scope.answer = 'Your Answer is Incorrect';
            $scope.backgroundColor = 'red';
            delete $scope.statement;
            delete $scope.answerData;
            delete $scope.correctData;
          });
      })
    // if the submitted answer conneciton fails
      .error(() => {
        $scope.answer = 'Your Answer is Incorrect';
        $scope.backgroundColor = 'red';
        delete $scope.statement;
        delete $scope.answerData;
        delete $scope.correctData;
      });
  };
});
