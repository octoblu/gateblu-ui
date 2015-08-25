angular.module 'gateblu-ui'
.directive 'fullScreenMessage', ->
  restrict: 'E'
  scope:
    message: '@'
  templateUrl: 'pages/full-screen-message.html'
