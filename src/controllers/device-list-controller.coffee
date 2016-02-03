class DeviceListController
  constructor: (dependencies={}) ->
    @rootScope = dependencies.rootScope
    @scope = dependencies.scope
    @GatebluServiceManager = dependencies.GatebluServiceManager
    @DeviceLogService = dependencies.DeviceLogService
    @DeviceService = dependencies.DeviceService
    @mdDialog = dependencies.mdDialog

    @scope.DEBUG_SWITCHING_ACTIVE = true

    @scope.getDeviceName = (device) =>
      return '[Initializing...]' if device.initializing
      return '[Missing Name]' unless device.name?
      return device.name

    @scope.isInDebugMode = (device) =>
      return device?.env?.DEBUG?

    @scope.turnOnDebug = (device) =>
      debugEnv = "#{device.connector}*"
      query = $set: "env.DEBUG": debugEnv
      @DeviceService.updateDangerously device.uuid, query, @onDebugChangeResponse

    @scope.turnOffDebug = (device) =>
      query = $unset: "env.DEBUG": ""
      @DeviceService.updateDangerously device.uuid, query, @onDebugChangeResponse

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
          @rootScope.$broadcast 'device:unregistering', device
          @GatebluServiceManager.deleteDevice device

    @scope.stopDevice = (device) =>
      @rootScope.$broadcast 'device:stopping', device
      @GatebluServiceManager.deviceState device, false

    @scope.startDevice = (device) =>
      @rootScope.$broadcast 'device:starting', device
      @GatebluServiceManager.deviceState device, true

    @scope.showDevice = (device) =>
      alert = @mdDialog.alert
        title: device.name
        content: device.uuid
        theme: 'info'
        ok: 'Close'

      @mdDialog
        .show alert

    @scope.showDeviceLog = (device) =>
      @scope.deviceHasNewError?[device.uuid] = false
      @scope.deviceHasNewLog?[device.uuid] = false
      @rootScope.$broadcast 'log:open:device', device

    @rootScope.$on 'log:device:add', ($event, entry) =>
      @scope.deviceHasNewError ?= {}
      @scope.deviceHasNewError[entry.uuid] = @DeviceLogService.hasError entry.uuid
      @scope.deviceHasNewLog ?= {}
      @scope.deviceHasNewLog[entry.uuid] = !@scope.deviceHasNewError[entry.uuid]

  onDebugChangeResponse: (error) =>
    return console.error error if error?
    alertObj =
      title: 'Restart Service'
      content: "Debug mode changed. Restart the gateblu service by pressing the power button."
      ok: 'Okay'
      theme: 'warning'
    alert = @mdDialog.alert alertObj
    @mdDialog.show alert

angular.module 'gateblu-ui'
  .controller 'DeviceListController', ($rootScope, $scope, GatebluServiceManager, DeviceLogService, DeviceService, $mdDialog) ->
    new DeviceListController
      rootScope: $rootScope
      scope: $scope
      GatebluServiceManager: GatebluServiceManager
      DeviceLogService: DeviceLogService
      DeviceService: DeviceService
      mdDialog: $mdDialog
