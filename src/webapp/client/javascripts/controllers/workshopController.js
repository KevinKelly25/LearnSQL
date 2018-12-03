/**
 * workshopController.js - LearnSQL
 *
 * Christopher Innaco, Michael Torres
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the AngularJS controller used for students to send queries
 *  to class database for which they have access
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
    
    // Get the className from the classID using the '_' as a delimiter, 
    //  then make uppercase
    $scope.className = ($scope.classID.substr(0, $scope.classID.search("_"))).toUpperCase();
  };

  $scope.sendQuery = () => {
    $scope.submitQuery_Button = 'Running Query . . .';

    // Check if the user entered a query
    if (typeof $scope.userQuery == 'undefined') {
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
        
        /* 
         * Limit the parsable results to only those of interest 
         *  (the query results)
         */  
        queryResult = data[0];
        
        // Arrays to store character lengths to compare for table formatting
        var attributeCharLength = [];
        var resultCharLength = [];

        // Find the length of the characters for each attribute
        for(i = 0; i < Object.keys(queryResult).length; ++i) 
        {
          attributeCharLength[i] = (Object.keys(queryResult)[i]).length;
        }

        // Get the lengths of the result strings of the query
        for(i = 0; i < Object.keys(queryResult).length; ++i)
        {
          /* 
           * Get the string representation of the element using Object.keys, which will
           *  use the property name to reference the element. This method is used because
           *  using an integer to access an object's elements causes unwanted behavior 
           *  with named indices.
           */
          var currentResultString = String(queryResult[Object.keys(queryResult)[i]]);

          // Get the length of the element
          resultCharLength[i] = currentResultString.length;
  
        }

        // Array to store the formatted (padded) attribute headers
        formattedAttributes = Object.keys(queryResult);
        // Array to store the row which visually separates the attributes from the result rows
        separatorRow = [];

        // Determine the size of each column by comparing the arrays
        for(i = 0; i < Object.keys(queryResult).length; ++i)
        {
          // Pad the end of the string with spaces to match the length of the attribute it corresponds with
          if(attributeCharLength[i] > resultCharLength[i])
          {
            var currentResultString = String(queryResult[Object.keys(queryResult)[i]]);
            queryResult[Object.keys(queryResult)[i]] = currentResultString.padEnd(Number(attributeCharLength[i]));

            //console.log(JSON.stringify(queryResult[Object.keys(queryResult)[i]]));
          }
          else
          {
            var currentAttributeString = String(formattedAttributes[i]);
            formattedAttributes[i] = currentAttributeString.padEnd(Number(resultCharLength[i]));

            //console.log(JSON.stringify(formattedAttributes[i]));
          }

          // Set the formatting for the separator row
          separatorRow[i] = "-" + "-".repeat(String(formattedAttributes[i]).length) + "-+"; 

        }


//---------------------
        printToCommandHistory('\n' + `${$scope.classID}=> ` + $scope.userQuery + '\n');

        // Print the attributes of the query results
        for(i = 0; i < Object.keys(queryResult).length; ++i) 
        {
          //$scope.commandHistory += " | " + (Object.keys(queryResult)[i]);
          $scope.commandHistory += " | " + formattedAttributes[i];
        }

        printToCommandHistory(" | ");

        printToCommandHistory('\n');

        $scope.commandHistory += " +";

        // Print the separator row
        for(i = 0; i < separatorRow.length; ++i) 
        {
          
          $scope.commandHistory += separatorRow[i];
        }

        printToCommandHistory('\n');

        // Print the rows of the query results
        for (i in queryResult)
        {
          $scope.commandHistory += " | " + queryResult[i];
        }

        printToCommandHistory(" | ");
        //-------------

        $scope.columns = Object.keys(queryResult).length;
        $scope.tableResult = queryResult;
                
      })
      .error((error) => {
        $scope.error = true;
        $scope.success = false;
        $scope.message = error.status;
      });

      $scope.submitQuery_Button = 'Run Code'; 
  }

  $scope.clearHistory = () => {
    $scope.commandHistory = "";
  }

  function printToCommandHistory(input) {
    $scope.commandHistory += input;
    return;
  }

});
