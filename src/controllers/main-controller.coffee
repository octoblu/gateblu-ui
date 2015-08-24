_     = require 'lodash'
shell = require 'shell'
stringify = require 'json-stringify-safe'

class MainController
  constructor: (dependencies={}) ->
    @rootScope = dependencies.rootScope
    @scope = dependencies.scope
    @timeout = dependencies.timeout
    @GatebluServiceManager = dependencies.GatebluServiceManager
    @LogService = dependencies.LogService
    @DeviceLogService = dependencies.DeviceLogService
    @UpdateService = dependencies.UpdateService
    @GatebluBackendInstallerService = dependencies.GatebluBackendInstallerService
    @GatebluService = dependencies.GatebluService
    @DeviceManagerService = dependencies.DeviceManagerService
    @mdDialog = dependencies.mdDialog

    @colors = ['#b9f6ca', '#ffff8d', '#84ffff', '#80d8ff', '#448aff', '#b388ff', '#8c9eff', '#ff8a80', '#ff80ab']

    @LogService.add 'Starting up!'

    @setupRootScope()
    @setupScope()
    @checkVersions()

    setInterval =>
      @checkVersions()
    , 1000 * 60 * 30

    @GatebluServiceManager.whoami (error, data) =>
      @scope.gateblu = data unless error?

  updateDevice: (device) =>
    filename = device.type?.replace ':', '/'
    device.icon_url = "https://ds78apnml6was.cloudfront.net/#{filename}.svg"
    device.colorInt ?= parseInt(device.uuid[0..6], 16) % @colors.length
    device.background = @colors[device.colorInt]
    device.col_span ?= 1
    device.row_span ?= 1
    if device.online == false
      device.background = '#f5f5f5'

    return device

  checkVersions: =>
    @UpdateService.checkServiceVersion (error, serviceUpdateAvailable, serviceVersion, newServiceVersion) =>
      return console.error 'Error', error.message if error?
      @UpdateService.checkUiVersion (error, uiUpdateAvailable, uiVersion, newUiVersion) =>
        return console.error 'Error', error.message if error?
        @timeout =>
          @scope.serviceVersion = serviceVersion
          @scope.newServiceVersion = newServiceVersion
          @scope.uiVersion = uiVersion
          @scope.newUiVersion = newUiVersion
          @scope.serviceUpdateAvailable = serviceUpdateAvailable
          @scope.uiUpdateAvailable = uiUpdateAvailable
          @scope.serviceInstallerLink = @GatebluServiceManager.getInstallerLink "v#{newServiceVersion}"
          @scope.uiInstallerLink = @scope.getInstallerLink "v#{newUiVersion}"
        , 0

  setupRootScope: =>
    @rootScope.$on "gateblu:connected", ($event) =>
      @scope.connecting = false
      @scope.refreshing = true
      @LogService.add "Gateblu Connected"

    @rootScope.$on "gateblu:disconnected", ($event) =>
      @scope.connecting = true
      @LogService.add "Gateblu Disconnected"

    @rootScope.$on 'gateblu:refreshDevices', ($event, data={}) =>
      @scope.deviceUuids = data.deviceUuids
      @scope.refreshing = true

    @rootScope.$on 'gateblu:devices', ($event, devices) =>
      @scope.devices = _.map devices, @updateDevice
      uuids = _.pluck @scope.devices, 'uuid'
      @scope.refreshing = ! _.isEqual uuids, @scope.deviceUuids

    @rootScope.$on 'error', ($event, error) =>
      alert = @mdDialog.alert
        title: 'An error has occurred'
        content: error.message

      @mdDialog
        .show alert

  setupScope: =>
    @scope.connecting = true
    @scope.refreshing = false
    @scope.isInstalled = @GatebluServiceManager.isInstalled()

    @scope.toggleDevice = _.debounce (device) =>
      if device.online
        @GatebluServiceManager.stopDevice device
      else
        @GatebluServiceManager.startDevice device
    , 500, {leading: true, trailing: false}

    @scope.getInstallerLink = (version='latest') =>
      baseUrl = "https://s3-us-west-2.amazonaws.com/gateblu/gateblu-ui/#{version}"
      if process.platform == 'darwin'
        filename = 'Gateblu.dmg'

      if process.platform == 'win32'
        filename = "gateblu-win32-#{process.arch}.exe"

      "#{baseUrl}/#{filename}"

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

    @scope.listenToDevice = (device) =>
      @GatebluServiceManager.getLogForDevice device.uuid

    @scope.toggleDeviceLog = (uuid) =>
      return @scope.showLogForDevice = null if !_.isEmpty @scope.showLogForDevice
      @scope.showLogForDevice = uuid;

    @scope.showDevice = (device) =>
      alert = @mdDialog.confirm
        title: device.name
        content: device.uuid
        theme: 'info'
        cancel: 'Close'
        ok: 'Show Logs'

      @mdDialog
        .show alert
        .then =>
          alert = undefined
          @scope.toggleDeviceLog device.uuid
        .catch =>
          alert = undefined

    @scope.claimGateblu = =>
      @GatebluServiceManager.generateSessionToken (error, result) =>
        shell.openExternal "https://app.octoblu.com/node-wizard/claim/#{result.uuid}/#{result.token}"

    @scope.hardRestartGateblu = =>
      alert = @mdDialog.confirm
        title: 'Hard Restart Gateblu'
        content: 'This will stop gateblu service, remove the devices and modules cache, then start gateblu. It will take a few minutes to redownload and configure the devices.'
        ok: 'Hard Restart'
        cancel: 'Cancel'
        theme: 'warning'

      @scope.serviceChanging = true

      @mdDialog
        .show alert
        .then =>
          @GatebluServiceManager.hardRestartGateblu (error) =>
            @timeout =>
              @scope.serviceChanging = false
            , 1000
            @scope.showError error if error?
        .catch =>
          @scope.serviceChanging = false

    @scope.resetGateblu = =>
      alert = @mdDialog.confirm
        title: 'Reset Gateblu'
        content: 'Do you want to reset your Gateblu? This will unregister it from your account and remove all your things.'
        ok: 'Reset'
        cancel: 'Cancel'
        theme: 'warning'

      @mdDialog
        .show alert
        .then =>
          @GatebluService.resetGateblu (error) =>
            @scope.showError error if error?

    @scope.showError = (error) =>
      alert = @mdDialog.alert
        title: 'Error'
        content: error?.message ? error
        ok: 'Okay'
        theme: 'info'

      @mdDialog
        .show alert

    @scope.toggleService = =>
      @scope.serviceChanging = true
      if @scope.serviceStopped
        @GatebluServiceManager.startService (error) =>
          @LogService.add error if error?
          @timeout =>
            @scope.serviceChanging = false
            @scope.serviceStopped = false
          , 1000
      else
        @GatebluServiceManager.stopService (error) =>
          @LogService.add error if error?
          @timeout =>
            @scope.serviceChanging = false
            @scope.serviceStopped = true
          , 1000

    @scope.$on "gateblu:unregistered", ($event, device) =>
      msg = "#{device.name} (~#{device.uuid}) has been deleted"
      @LogService.add msg
      alert = @mdDialog.alert
        title: 'Deleted'
        content: msg
        ok: 'Close'
        theme: 'info'

      @mdDialog
        .show alert
        .finally =>
          alert = undefined

angular.module 'gateblu-ui'
  .controller 'MainController', ($rootScope, $scope, $timeout, GatebluServiceManager, LogService, DeviceLogService, UpdateService, GatebluBackendInstallerService, GatebluService, DeviceManagerService, $mdDialog) ->
    new MainController
      rootScope: $rootScope
      scope: $scope
      timeout: $timeout
      mdDialog: $mdDialog
      GatebluServiceManager: GatebluServiceManager
      LogService: LogService
      DeviceLogService: DeviceLogService
      UpdateService: UpdateService
      GatebluBackendInstallerService: GatebluBackendInstallerService
      GatebluService: GatebluService
      DeviceManagerService: DeviceManagerService
