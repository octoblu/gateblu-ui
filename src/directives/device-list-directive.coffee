angular.module 'gateblu-ui'
  .directive 'deviceList', ->
    restrict: 'E'
    scope:
      devices: '='
    templateUrl: 'pages/device-list.html'
    link: ($scope, element, attrs) =>
      $scope.devices = attrs.devices
