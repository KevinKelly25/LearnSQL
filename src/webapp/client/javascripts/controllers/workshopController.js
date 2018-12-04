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

        printToCommandHistory($scope.userQuery + '\n\n');

        /**
         * Limit the parsable results to only those of interest 
         *  (the query results)
         */  

        queryResult = data;

        var attributeCharLength = findAttributeLength(queryResult[0]);

        var resultCharLength = [];
        
        // Find the longest string for every column in each row
        for(i in data)
        {
          queryResult = data[i];
          resultCharLength[i] = storeColumnWidth(queryResult);
        }

       // console.log("Before resultCharLength");
       // console.log(resultCharLength);
        resultCharLength = compareWidths(resultCharLength);
       // console.log("After resultCharLength");
       // console.log(resultCharLength);

        formattedResults = [];
        
        for(i in data)
        {
          queryResult = data[i];
          formattedAttributes = setColumnWidth(queryResult, attributeCharLength, resultCharLength);

        }
        separatorRow = formatSeparatorRow(formattedAttributes);

        printHeader(queryResult, formattedAttributes, separatorRow);


        for(i in data)
        {
          queryResult = data[i];
          printToCommandHistory('\n');
          printRow(queryResult);
        }
                
        nextCommandPrompt();
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

  function storeColumnWidth(queryResult) {

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
      
      resultCharLength[i] = currentResultString.length;
    }

    return resultCharLength;
  }

  function compareWidths(resultCharLength) {

    resultCharLength_Parsed = [];

    // Store the largest string length in the first array of arrays
      for(i = 0; i < Object.keys(resultCharLength).length; ++i)
      {
        subArray = resultCharLength[i];
        for(j = 0; j < Object.keys(subArray).length; ++j)
        {
          
          columnWidth = [];
          for(k = 0; k < Object.keys(resultCharLength).length; ++k)
          {       
            // Find the max width by comparing rows in the same column 
            columnWidth.push(resultCharLength[k][j]);           
          }
 
         // console.log("MAX:");
         // console.log(Math.max(...columnWidth));
          resultCharLength_Parsed.push(Math.max(...columnWidth));
        }

        break;
      }
      console.log(resultCharLength_Parsed);

    return resultCharLength_Parsed;
  }

  function setColumnWidth(queryResult, attributeCharLength, resultCharLength) {

    // Array to store the formatted (padded) attribute headers
    formattedAttributes = Object.keys(queryResult);

    // Determine the size of each column by comparing the arrays
    for(i = 0; i < Object.keys(queryResult).length; ++i)
    {
      // Pad the end of the column with spaces to match the length of the attribute it corresponds with
      if(attributeCharLength[i] > resultCharLength[i])
      {
        var currentResultString = String(queryResult[Object.keys(queryResult)[i]]);
        queryResult[Object.keys(queryResult)[i]] = currentResultString.padEnd(Number(attributeCharLength[i]));

      }
      else
      {
        // If the attribute string is shorter, pad the end using the length of the longest string in the column
        var currentResultString = String(queryResult[Object.keys(queryResult)[i]]);
        queryResult[Object.keys(queryResult)[i]] = currentResultString.padEnd(Number(resultCharLength[i]));

        var currentAttributeString = String(formattedAttributes[i]);
        formattedAttributes[i] = currentAttributeString.padEnd(Number(resultCharLength[i]));

      }
    }

    return formattedAttributes;
  }

  function formatSeparatorRow(fromAttributeLength) {
    
    // Array to store the row which visually separates the attributes from the result rows
    separatorRow = [];

    for(i = 0; i < Object.keys(queryResult).length; ++i)
    {
      // Set the formatting for the separator row using `psql` style
      separatorRow[i] = "-" + "-".repeat(String(fromAttributeLength[i]).length) + "-+";
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

  }

  function printRow(queryResult) {

    // Print the rows of the query results
    for (i in queryResult) 
    { 
      $scope.commandHistory += " | " + queryResult[i];
    }

    printToCommandHistory(" | ");
  
    return;
  }

  function nextCommandPrompt() {
    printToCommandHistory('\n\n' + $scope.classID + "=> ");
  }

  function printToCommandHistory(input) {
    $scope.commandHistory += input;
    return;
  }
});
