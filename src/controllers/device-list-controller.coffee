class DeviceListController
  constructor: (dependencies={}) ->
    @rootScope = dependencies.rootScope
    @scope = dependencies.scope
    @GatebluServiceManager = dependencies.GatebluServiceManager
    @mdDialog = dependencies.mdDialog

    @scope.deleteDevice = (device) =>
      alert = @mdDialog.confirm
        title: 'Are you sure?'
        content: "This will remove #{device.name} ~#{device.uuid}"
        ok: 'Delete'
        cancel: 'Cancel'
        theme: 'confirm'

      @mdDialog
        .show alert
        .then =>
          @GatebluServiceManager.deleteDevice device

    @scope.showDevice = (device) =>
      alert = @mdDialog.alert
        title: device.name
        content: device.uuid
        theme: 'info'
        ok: 'Close'

      @mdDialog
        .show alert

    @scope.showDeviceLog = (device) =>
      @rootScope.$broadcast 'log:open:device', device

angular.module 'gateblu-ui'
  .controller 'DeviceListController', ($rootScope, $scope, GatebluServiceManager, $mdDialog) ->
    new DeviceListController
      rootScope: $rootScope
      scope: $scope
      GatebluServiceManager: GatebluServiceManager
      mdDialog: $mdDialog
