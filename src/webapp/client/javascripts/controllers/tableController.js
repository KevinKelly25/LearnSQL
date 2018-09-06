/**
 * tableController.js - LearnSQL
 *
 * Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the angularJS controller used for viewing tables
 */



app.controller('tableCtrl', ($scope, $http, $location) => {
  $scope.view = 'allTables';// default view of the table

  /**
   * This function initializes the table that contains all the user's tables in
   *  ClassDB database. The class and username are supplied by URL parameters.
   *  An example of a possible acceptable URL is shown here:
   * http://localhost:3000/table/#?username=teststu1&classID=testing1_1lvc01hojllf1r02
   */
  $scope.initTables = () => {
    $scope.userInfo = {
      username: $location.search().username,
      class: $location.search().classID,
    };
    $http.post('/getTables', $scope.userInfo)
      .success((data) => {
        $scope.tables = data;
      });
  };


  /**
   * This function is given a table name and with URL parameters username and
   *  classID it forms an object tableInfo. This object is passed to route
   *  getTable which returns a table in JSON. It also switches view to
   *  a view of the returned table.
   *
   * @param {string} tableName the name of the table that will be retrieved
   */
  $scope.getTable = (tableName) => {
    $scope.tableInfo = {
      name: tableName,
      schema: $location.search().username,
      classID: $location.search().classID,
    };

    // switch to another form
    $scope.view = 'oneTable';

    // get table details/rows
    $http.post('/getTable', $scope.tableInfo)
      .success((data) => {
        $scope.columns = Object.keys(data[0]);// the amount of columns
        $scope.table = data;
      });
  };


  /**
   * This function is used to go from single table view to view of all tables.
   *  It also clears the data stored in the single table view.
   */
  $scope.backToTables = () => {
    // switch to another form
    $scope.view = 'allTables';
    delete $scope.table;
    delete $scope.columns;
  };
});
