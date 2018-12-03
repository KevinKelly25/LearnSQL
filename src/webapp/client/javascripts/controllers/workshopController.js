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
    
    // Get the classID to create the connection string to send queries 
    //  to the class's database
    $scope.classID = $location.search().class;

    // Clear the command history box to append query results to
    $scope.commandHistory = "";
    $scope.clearHistory();
    
    // Get the className from the classID using the '_' as a delimiter, 
    //  then make uppercase
    $scope.className = ($scope.classID.substr(0, $scope.classID.search("_"))).toUpperCase();
  };

  $scope.sendQuery = () => {
    $scope.submitQuery_Button = 'Running Query . . .';

    // Check if the user entered a query
    if (typeof $scope.userQuery == 'undefined') {
      printToCommandHistory('\n' + "No query was entered. Try again.");
      printToCommandHistory('\n\n' + $scope.classID + "=> ");
      $scope.submitQuery_Button = 'Run Code';  
      return;
    }

    $scope.queryInfo = {
      userQuery: $scope.userQuery,
      classID: $scope.classID,
    };

    $http.post('/workshop/sendQuery', $scope.queryInfo)
      .success((data) => {

        console.log("Client Query Result: ");
        console.log(data);

        // If the entered query produced successful results and has no return value
        if(!Array.isArray(data) || !data.length)
        {
          printToCommandHistory('\n' + "Operation completed successfully");
          printToCommandHistory('\n\n' + $scope.classID + "=> ");
          return;
        }

        /**
         * Limit the parsable results to only those of interest 
         *  (the query results)
         */  
        //queryResult = data[0];

        /*determineColumnWidth(compareStringLengths());
        printQueryResultTable();*/

        queryResult = data;
        //console.log(queryResult.length);

        var attributeCharLength = findAttributeLength(queryResult[0]);

        var resultCharLength;
        
        for(i in data)
        {
          console.log(`data[${i}]`);
          queryResult = data[i];
          resultCharLength = findResultCharLength(queryResult);
          
        }

        console.log("resultCharLength: ");
        console.log(resultCharLength);

        formattedAttributes = determineColumnWidth(attributeCharLength, resultCharLength)
        separatorRow = formatSeparatorRow(formattedAttributes);

        printToCommandHistory($scope.userQuery + '\n');

        printHeader(queryResult, formattedAttributes, separatorRow);

        for(i in data)
        {
          queryResult = data[i];
          printRow(queryResult);
        }
        
        
      

      })

      .error((error) => {
        printToCommandHistory('\n' + "Error: " + error.status);
        printToCommandHistory('\n\n' + $scope.classID + "=> ");
      });

      $scope.submitQuery_Button = 'Run Code';
  }

  $scope.clearHistory = () => {
    $scope.commandHistory = `${$scope.classID}=> `;
  }

  function findAttributeLength(queryResult) {
    attributeCharLength = [];

    // Find the length of the characters for each attribute
    for(i = 0; i < Object.keys(queryResult).length; ++i) 
    {
      attributeCharLength[i] = (Object.keys(queryResult)[i]).length;
    }

    return attributeCharLength;
  }

  function findResultCharLength(queryResult) {

    var resultCharLength = [];

    // Get the lengths of the result strings of the query
    for(i = 0; i < Object.keys(queryResult).length; ++i)
    {
      /** 
       * Get the string representation of the element using Object.keys, which will
       *  use the property name to reference the element. This method is used because
       *  using an integer to access an object's elements causes unwanted behavior 
       *  with named indices.
       */
      var currentResultString = String(queryResult[Object.keys(queryResult)[i]]);

      // Get the length of the element and ensure the largest character length is assigned as the element
      if(resultCharLength[i] < currentResultString.length)
      {
        resultCharLength[i] = currentResultString.length;
      }
      else if (resultCharLength[i] == null)
      {
        resultCharLength[i] = currentResultString.length;
      }
      else
      {
        continue;
      }
    }

    return resultCharLength;
  }

  function determineColumnWidth(attributeCharLength, resultCharLength) {

    // Array to store the formatted (padded) attribute headers
    formattedAttributes = Object.keys(queryResult);

    // Determine the size of each column by comparing the arrays
    for(i = 0; i < Object.keys(queryResult).length; ++i)
    {
      // Pad the end of the string with spaces to match the length of the attribute it corresponds with
      if(attributeCharLength[i] > resultCharLength[i])
      {
        var currentResultString = String(queryResult[Object.keys(queryResult)[i]]);
        queryResult[Object.keys(queryResult)[i]] = currentResultString.padEnd(Number(attributeCharLength[i]));
      }
      else
      {
        var currentAttributeString = String(formattedAttributes[i]);
        formattedAttributes[i] = currentAttributeString.padEnd(Number(resultCharLength[i]));
      }
    }

    return formattedAttributes;
  }

  function formatSeparatorRow(fromStringLength) {
    
    // Array to store the row which visually separates the attributes from the result rows
    separatorRow = [];

    for(i = 0; i < Object.keys(queryResult).length; ++i)
    {
      // Set the formatting for the separator row using `psql` style
      separatorRow[i] = "-" + "-".repeat(String(fromStringLength[i]).length) + "-+";
    }
    return separatorRow;
  }

  function printHeader(queryResult, formattedAttributes, separatorRow) {
  
    // Print the attributes of the query results
    for(i = 0; i < Object.keys(queryResult).length; ++i) 
    {
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
  }

  function printRow(queryResult) {

    // Print the rows of the query results
    for (i in queryResult) 
    { 
      $scope.commandHistory += " | " + queryResult[i];
    }
  
    printToCommandHistory(" | ");

    printToCommandHistory('\n\n' + $scope.classID + "=> ");

    return;
  }

  function printToCommandHistory(input) {
    $scope.commandHistory += input;
    return;
  }
});
