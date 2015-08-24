angular.module 'gateblu-ui'
.directive 'log', ->
  restrict: 'E'
  templateUrl: 'pages/log.html'
  scope:
    title: '='
    logLines: '='
  controller: 'LogController'
