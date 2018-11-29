/**
 * workshopController.js - LearnSQL
 *
 * Christopher Innaco, Michael Torres
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the AngularJS controller used for users to be able to view
 *  log into their class database.
 */

/* eslint-disable no-param-reassign */


app.controller('workshopCtrl', ($scope, $http, $location) => {
  $scope.initClasses = () => {
    $http.get('/workshop/getClasses')
      .success((data) => {
        data.forEach((element) => {
          element.classname = element.classname.toUpperCase();
        });

        $scope.classes = data;
      });
  };

  $scope.initClass = () => {
    // Set the submit button text
    $scope.submitQuery_Button = 'Run Code';
    
    // Clear the command history box to append query results to
    $scope.commandHistory = "";

    // Get the classID to create the connection string to send queries 
    //  to the class's database
    $scope.classID = $location.search().class;
    
    // Get the className from the classID using the '_' as a delimiter
    $scope.className = ($scope.classID.substr(0, $scope.classID.search("_"))).toUpperCase();
  };

  $scope.sendQuery = () => {
    $scope.submitQuery_Button = 'Running Query . . .';

    // Check if the user entered a query
    if (typeof $scope.userQuery == 'undefined')
    {
      printToCommandHistory("No query was entered. Try again.");
      $scope.submitQuery_Button = 'Run Code';  
      return;
    }

    $scope.queryInfo = {
      userQuery: $scope.userQuery,
      classID: $scope.classID,
    };

    $http.post('/workshop/sendQuery', $scope.queryInfo)
      .success((data) => {
        
        // Limit the parsable results to only those of interest 
        //  (the query results)
        queryResult = data[0];

        // Get the property name of the first element, access it and print it
        printToCommandHistory(queryResult[Object.keys(data[0])]);
                
      })
      .error((error) => {
        $scope.error = true;
        $scope.success = false;
        $scope.message = error.status;
      });

      $scope.submitQuery_Button = 'Run Code'; 
  }

  function printToCommandHistory(input)
  {
    $scope.commandHistory += "> " + input + '\n';
    return;
  }

});
