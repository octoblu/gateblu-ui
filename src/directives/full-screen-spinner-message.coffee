angular.module 'gateblu-ui'
.directive 'fullScreenMessage', ->
  restrict: 'E'
  scope:
    message: '@'
    buttonTitle: '@'
    eventName: '@'
  templateUrl: 'pages/full-screen-message.html'
  controller: 'FullscreenController'
