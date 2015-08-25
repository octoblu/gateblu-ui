angular.module 'gateblu-ui'
.directive 'fullScreenMessage', ->
  restrict: 'E'
  scope:
    message: '='
    buttonTitle: '='
    eventName: '='
    spinner: '='
  templateUrl: 'pages/full-screen-message.html'
  controller: 'FullscreenController'
