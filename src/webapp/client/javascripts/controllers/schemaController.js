/**
 * schemaController.js - LearnSQL
 *
 * Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the angularJS controller used for viewing objects
 */



app.controller('schemaCtrl', ($scope, $http, $location) => {
  $scope.view = 'allObjects';// default view of the table


  // Converts the date from postgres format to readable format
  function convertDate(inputDateString) {
    const date = new Date(inputDateString);
    return `${date.toDateString()}`;
  }

  // Converts the timestamp from postgres format to readable format
  function convertTimeStamp(inputTimestampString) {
    const date = new Date(inputTimestampString.replace(' ', 'T'));
    return `${date.toDateString()} ${date.toLocaleTimeString('nb-NO')}`;
  }

  // Converts the timestampTZ from postgres format to readable format
  function convertTimeStampTZ(inputTimestampString) {
    const date = new Date(inputTimestampString.replace(' ', 'T'));
    return `${date}`;
  }

  /**
   * This function initializes the table that contains all the user's objects in
   *  ClassDB database. The class and username are supplied by URL parameters.
   *  An example of a possible acceptable URL is shown here:
   * http://localhost:3000/schema/#?username=teststu1&classID=testing1_1lvc01hojllf1r02
   */
  $scope.initSchema = () => {
    $scope.userInfo = {
      username: $location.search().username,
      class: $location.search().classID,
    };
    $http.post('/getObjects', $scope.userInfo)
      .success((data) => {
        $scope.schema = data;
      });
  };


  /**
   * This function is supplied a object name and type as parameters. With URL
   *  parameters username and classID are extracted. These four parameters form
   *  the object tableInfo. This object is passed to route getObjectDetails
   *  which returns a object details in JSON. It also switches view to
   *  allow user to see details.
   *
   * @param {string} objectName The name of the object that will be retrieved
   * @param {string} type The type of the object
   */
  $scope.getObjectDetails = (name, type) => {
    $scope.objectInfo = {
      objectName: name,
      objectType: type,
      schema: $location.search().username,
      classID: $location.search().classID,
    };

    // Use http post route to get the object details
    $http.post('/getObjectDetails', $scope.objectInfo)
      .success((data) => {
        if (type === 'TABLE') {
          // Check to make sure at least 1 column was returned so that code
          //  doesn't try to access undefined object
          if (Object.keys(data.result).length !== 0) {
            $scope.columns = Object.keys(data.result[0]);// the amount of columns
            $scope.tableResult = data.result;
            const types = data.details[0].attributes.split(',');
            for (let i = 0; i < types.length; i++) {
              if (types[i].trim() === 'date') {
                data.result.forEach((element) => {
                  element[$scope.columns[i]] = convertDate(element[$scope.columns[i]]);
                });
              } else if (types[i].trim() === 'timestamp') {
                data.result.forEach((element) => {
                  element[$scope.columns[i]] = convertTimeStamp(element[$scope.columns[i]]);
                });
              } else if (types[i].trim() === 'timestamptz') {
                data.result.forEach((element) => {
                  element[$scope.columns[i]] = convertTimeStampTZ(element[$scope.columns[i]]);
                });
              }
            }
          }
          $scope.tableInfo = data.details;
        } else if (type === 'VIEW') {
          // Check to make sure at least 1 column was returned so that code
          //  doesn't try to access undefined object
          if (Object.keys(data.result).length !== 0) {
            $scope.columns = Object.keys(data.result[0]);// The amount of columns
            $scope.viewResult = data.result;
          }
          $scope.viewInfo = data.details;
        } else if (type === 'INDEX') {
          $scope.indexInfo = data;
        } else if (type === 'TRIGGER') {
          $scope.triggerInfo = data;
        } else { // Should be a function
          $scope.functionInfo = data;
          if (!$scope.functionInfo[0].argumenttypes) {
            $scope.functionInfo[0].argumenttypes = 'None';
          }
        }
        $scope.view = 'objectDetailsView';
      });
  };


  /**
   * This function is used to go from single object view to view of all objects.
   *  It also clears the data stored in the single object view.
   */
  $scope.backToObjects = (type) => {
    // Delete the object details
    switch (type) {
      case 'table':
        delete $scope.tableInfo;
        delete $scope.tableResult;
        break;
      case 'view':
        delete $scope.viewInfo;
        delete $scope.viewResult;
        break;
      case 'function':
        delete $scope.functionInfo;
        break;
      case 'trigger':
        delete $scope.triggerInfo;
        break;
      case 'index':
        delete $scope.indexInfo;
        break;
      default:
        break;
    }
    // Switch to main view
    $scope.view = 'allObjects';
  };
});
