/**
 * adminController.js - LearnSQL
 *
 * Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the angularJS controller used for the admin functionality
 *  on the LearnSQL website
 */



/**
 * This controller is used for the admin control panel to add classes
 */
app.controller('AdminCtrl', ($scope, $http) => {
  $scope.form = 'default';
  $scope.error = false;
  $scope.success = false;

  // class information
  this.class = {
    name: null,
    password: null,
  };
  $scope.output = 'Class info will displayed here, it will unformatted';



  /**
   * This function calls the /admin/addClass post method to create ClassDB databases
   *  and updates the associated LearnSQL tables. While processing a message
   *  appears to let the user know to wait.
   */
  $scope.addClass = () => {
    $scope.error = false;
    this.class.name = $scope.class;
    this.class.password = $scope.password;
    $scope.success = true;
    $scope.message = 'Database Being Created, Please Wait';

    // make sure that is a valid name
    const regex = new RegExp('^[a-zA-Z0-9_]*$');
    if (regex.test(this.class.name)) {
      $http.post('/admin/addClass', this.class)
        .success(() => {
          $scope.success = true;
          $scope.message = 'Database Successfully Created';
        })
        .error((error) => {
          $scope.success = false;
          $scope.error = true;
          $scope.message = error.status;
        });
    } else {
      $scope.message = 'Invalid Characters Detected! Please Use only the following '
                       + 'characters: A-Z, 0-9, - only (case insensitive)';
    }
  };



  /**
     * This function is an example of how to add student via angularjs
     */
  $scope.addStudent = () => {
    $scope.error = false;
    $scope.success = true;
    $scope.student = {
      username: $scope.username,
      fullname: $scope.fullName,
      classname: $scope.className2,
    };
    $scope.message = 'adding student';
    $http.post('/teacher/addStudent', $scope.student)
      .success((data) => {
        $scope.success = true;
        $scope.message = 'Student Added Successfully';
        $scope.output = data;
      })
      .error((error) => {
        $scope.success = false;
        $scope.error = true;
        $scope.message = error.status;
      });
  };



  /**
     * This function is an example of how to retrieve class info via angularJS
     */
  $scope.getClass = () => {
    $scope.error = false;
    $scope.success = true;
    $scope.getclass = {
      classname: $scope.className,
    };
    $http.post('/teacher/getClass', $scope.getclass)
      .success((data) => {
        $scope.success = true;
        $scope.message = 'Got Data';
        $scope.output = data;
      })
      .error(() => {
        $scope.success = false;
        $scope.error = true;
        $scope.message = $scope.getclass;
      });
  };



  /**
     * This function is an example of how to remove student via angularjs
     */
  $scope.dropStudent = () => {
    $scope.error = false;
    $scope.success = true;
    $scope.student2 = {
      username: $scope.studentName,
      classname: $scope.className3,
    };
    $http.post('/teacher/dropStudent', $scope.student2)
      .success(() => {
        $scope.success = true;
        $scope.message = 'dropped student';
      })
      .error((error) => {
        $scope.success = false;
        $scope.error = true;
        $scope.message = error;
      });
  };
});
