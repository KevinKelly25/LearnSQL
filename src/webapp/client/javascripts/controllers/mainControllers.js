/**
 * mainControllers.js - LearnSQL
 *
 * Kevin Kelly, Michael Torres
 * Web Applications and Databases for Education (WADE)
 *
 * This file contains the Main angularJS controllers that are used throughout the
 * LearnSQL website
 */

const app = angular.module('LearnSQL', ['datatables', 'luegg.directives']);

/**
 * This provides the functionality of creating a new directive using the
 *  .directive function syntaxHighlight
 */
app.directive('syntaxHighlight', [function () { // eslint-disable-line func-names
  return {
    restrict: 'C', // determines that a directive can be used only on a class.
    scope: {
      source: '@', // @ reads the attribute value
    },
    link(scope, element) { // DOM manipulation
      scope.$watch('source', (v) => {
        if (v) {
          Prism.highlightElement(element.find('code')[0]); // eslint-disable-line no-undef
        }
      });
    },
    template: "<code ng-bind='source'></code>",
  };
}]);

/**
 * This controller is used to dynamically display the navbar of the website
 *  to show whether a user is logged in or not.
 */
app.controller('NavCtrl', ($scope, $http, $window) => {
  $scope.currentUser = {};
  $scope.message = 'message';

  /**
   * This function is used to log the user out. The functionality is primarily
   *  in the REST api /auth/logout function. If logout is sucessful init() is called
   *  which will refresh the values on the page. This is done once the currentUser
   *  is updated.
   */
  $scope.logout = () => {
    $http.get('/auth/logout')
      .success(() => {
        $window.location.href = 'http://localhost:3000';
      });
  };

  /**
   * This function is used to check the current user, if any. If there is a user
   *  the current user will be updated with its user information. The functionality
   *  is primarily in the REST api /auth/check function.
   */
  $scope.init = () => {
    $http.get('/auth/check')
      .success((data) => {
        $scope.currentUser = data;
      });
  };
});
