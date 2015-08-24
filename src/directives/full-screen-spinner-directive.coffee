angular.module 'gateblu-ui'
.directive 'fullScreenSpinner', ->
  restrict: 'E'
  templateUrl: 'pages/full-screen-spinner.html'
  link: ($scope, element, attrs) =>
    $scope.message = attrs.message
