/**
 * teacherController.js - LearnSQL
 *
 * Michael Torres, Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the angularJS controller used for the teacher functionality
 *  on the LearnSQL website
 */
/* eslint-disable no-param-reassign */



/**
 * This controller is used for teacher related angular functionality.
 */
app.controller('teacherCtrl', ($scope, $http, $location, $window) => {
  $scope.class = {
    name: 'something',
  };


  // Converts the date from postgres format to readable format
  function convertDate(inputDateString) {
    const date = new Date(inputDateString);
    return `${date.getHours()}:${date.getMinutes()}   ${
      date.getMonth() + 1}/${date.getDate()}/${date.getFullYear()}`;
  }


  /**
   * This function initializes the table in `teacherClasses.html` with all the
   *  classes the teacher is in.
   */
  $scope.initClasses = () => {
    $http.get('/teacher/getClasses')
      .success((data) => {
        $scope.classes = data;
      });
  };


  /**
   * This function initializes the table in `teacherClass.html` with the all the
   *  students in the class and associated student information. It also retrieves
   *  class information from the class view
   */
  $scope.initClass = () => {
    $scope.classInfo = {
      className: $location.search().class,
    };


    $http.post('/teacher/getStudents', $scope.classInfo)
      .success((data) => {
        data.forEach((element) => {
          element.lastddlactivityat = convertDate(element.lastddlactivityat);
        });
        $scope.class = data;
      });

    $scope.test = 'help';
    $http.post('/teacher/getClassInfo', $scope.classInfo)
      .success((data) => {
        $scope.classInfo = data;
      });
  };


  /**
   * This function calls the /admin/addClass post method to create ClassDB databases
   *  and updates the associated LearnSQL tables. While processing a message
   *  appears to let the user know to wait.
   */
  $scope.addClass = () => {
    $scope.error = false;
    $scope.success = true;
    $scope.message = 'Class Being Created, Please Wait';


    $scope.class = {
      name: $scope.className,
      section: $scope.section,
      times: $scope.times,
      days: $scope.days,
      startDate: $scope.startDate,
      endDate: $scope.endDate,
      password: $scope.password,
    };

    // Make sure that is a valid name
    const regex = new RegExp('^[a-zA-Z0-9_]*$');
    if (regex.test($scope.class.name)) {
      $http.post('/teacher/addClass', $scope.class)
        .success(() => {
          $scope.success = true;
          $scope.message = 'Class Successfully Created';
          $window.location.reload();
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
   * This function updates the dropClass object to the current className so that
   *  the correct class is displayed in the drop class warning modal. The
   *  updated dropClass object is also used as a parameter to drop the class in
   *  the dropClassTeacher function.
   *
   * @param {string} className The classname that needs to be displays
   */
  $scope.displayClassName = (className) => {
    $scope.success = false;
    $scope.error = false;
    $scope.dropClass = {
      name: className,
    };
  };


  /**
   * This function calls a http post method to drop a class. While waiting for
   *  response a message pops up that tells user to wait for completion. Upon
   *  success the user's class page will be reloaded to show updated information
   */
  $scope.dropClassTeacher = () => {
    $scope.error = false;
    $scope.success = true;
    $scope.message = 'Class Being Dropped, Please Wait...';

    $http.post('/teacher/dropClass', $scope.dropClass)
      .success(() => {
        $scope.success = true;
        $scope.message = 'Class Successfully Dropped';
        $window.location.reload();
      })
      .error((error) => {
        $scope.success = false;
        $scope.error = true;
        $scope.message = error.status;
      });
  };
});