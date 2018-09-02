/**
 * teacherController.js - LearnSQL
 *
 * Michael Torres, Kevin Kelly
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the angularJS controller used for the teacher functionality
 *  on the LearnSQL website
 */


var app = angular.module('LearnSQL');


/**
 * This controller is used for the teacher control panel to add classes
 */
app.controller('teacherCtrl', ($scope, $http, $location, $window) => {
  $scope.class = {
    name: 'something'
  };

  //Converts the date from postgres format to readable format
  function convertDate(inputDateString){
    var date = new Date(inputDateString);
    return date.getHours() + ":" + date.getMinutes() + "   " 
      + (date.getMonth()+1) + "/" + date.getDate() + "/" + date.getFullYear();
  }



  /**
   * This function initializes the table in `teacherClasses.html` with the 
   *  all the classes the teacher is in.  
   */
  $scope.initClasses = () => {
    $http.get('/teacher/getClasses')
    .success((data) => {
      $scope.classes = data;
    })
    .error((error) => {
      //do something if encounters an error
    });
  }



  
  /**
   * This function initializes the table in `teacherClasses.html` with the 
   *  all the classes the teacher is in.  
   */
  $scope.initClass = () => {
    $scope.classInfo = {
      className: $location.search().class
    };

    
    $http.post('/teacher/getStudents', $scope.classInfo)
    .success((data) => {
      data.forEach(element => {
        element.lastddlactivityat = convertDate(element.lastddlactivityat);
      });
      $scope.class = data;
    })
    .error((error) => {
      //do something if encounters an error
    });

    $scope.test = 'help';
    $http.post('/teacher/getClassInfo', $scope.classInfo)
    .success((data) => {
      $scope.classInfo = data;
    })
    .error((error) => {
      //do something if encounters an error
    });
  }


  
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
      password: $scope.password
    };

    //make sure that is a valid name
    var regex = new RegExp("^[a-zA-Z0-9_]*$");
    if (regex.test($scope.class.name))
    {
      $http.post('/teacher/addClass', $scope.class)
      .success((data) => {
        $scope.success = true;
        $scope.message = 'Class Successfully Created';
        $window.location.reload();
      })
      .error((error) => {
        $scope.success = false;
        $scope.error = true;
        $scope.message = error.status;
      });
    } else
    {
      $scope.message = 'Invalid Characters Detected! Please Use only the following ' +
                       'characters: A-Z, 0-9, - only (case insensitive)';
    }
  };



  $scope.displayClassName = (className) => {
    $scope.success = false;
    $scope.error = false;
    $scope.dropClass = {
      name: className
    };
  };



  $scope.dropClassTeacher = () => {
    $scope.error = false;
    $scope.success = true;
    $scope.message = 'Class Being Dropped, Please Wait...';

    $http.post('/teacher/dropClass', $scope.dropClass)
    .success((data) => {
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
