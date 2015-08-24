angular.module 'gateblu-ui'
.directive 'fullScreenSpinner', ->
  restrict: 'E'
  scope:
    message: '@'
  templateUrl: 'pages/full-screen-spinner.html'
