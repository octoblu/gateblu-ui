angular.module 'gateblu-ui'
  .controller 'DeviceLogController', ($scope, DeviceLogService) ->
    $scope.logs = DeviceLogService.all()
