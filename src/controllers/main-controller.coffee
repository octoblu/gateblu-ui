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
    @interval = dependencies.interval

    @colors = ['#b9f6ca', '#ffff8d', '#84ffff', '#80d8ff', '#448aff', '#b388ff', '#8c9eff', '#ff8a80', '#ff80ab']

    @LogService.add 'Starting up!'

    @setupRootScope()
    @setupScope()
    @checkVersions()

    @interval =>
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
      @LogService.add "Gateblu Connected"
      @scope.fullscreen =
        message: 'Loading Devices...'
        spinner: true

    @rootScope.$on 'gateblu:claim', ($event) =>
      @GatebluServiceManager.generateSessionToken (error, result) =>
        return @rootScope.$broadcast 'error', error if error?
        shell.openExternal "https://app.octoblu.com/node-wizard/claim/#{result.uuid}/#{result.token}"

    @rootScope.$on 'gateblu:config', ($event, config) =>
      @LogService.add 'Gateblu Config Changed'
      @scope.gatebluConfig = config
      @scope.fullscreen = null if @scope.fullscreen?.waitForConfig

    @rootScope.$on 'gateblu:device:config', ($event, config) =>
      device = _.findWhere @scope.devices, uuid: config.uuid
      if device
        device.online = config.online
        device.name = config.name

    @rootScope.$on 'gateblu:notReady', ($event, config) =>
      @LogService.add "Meshblu Authentication Failed"
      @scope.fullscreen =
        message: 'Meshblu Authentication Failed'

    @rootScope.$on "gateblu:disconnected", ($event) =>
      @LogService.add "Gateblu Disconnected"
      @scope.fullscreen =
        message: 'Reconnecting to Octoblu...'
        spinner: true

    @rootScope.$on 'gateblu:refreshDevices', ($event, data={}) =>
      @LogService.add 'Refreshing Devices'
      if _.isEmpty data.deviceUuids
        @scope.fullscreen = null
        return
      @scope.deviceUuids = data.deviceUuids
      @scope.fullscreen =
        message: 'Loading Devices...'
        spinner: true

    @rootScope.$on 'gateblu:devices', ($event, devices) =>
      @LogService.add 'Received Device List'
      @scope.devices = _.map devices, @updateDevice
      uuids = _.pluck @scope.devices, 'uuid'
      if _.isEqual uuids, @scope.deviceUuids
        @scope.fullscreen = null

    @rootScope.$on 'log:open:device', ($event, device) =>
      @scope.showLog = true
      @scope.logTitle = "Device Log (~#{device.uuid})"
      @scope.logLines = @DeviceLogService.get device.uuid

    @rootScope.$on 'log:close', ($event) =>
      @scope.showLog = false

    @rootScope.$on 'error', ($event, error) =>
      @LogService.add error?.message
      alert = @mdDialog.alert
        title: 'An error has occurred'
        content: error?.message
        ok: 'Close'

      @mdDialog
        .show alert

  setupScope: =>
    @scope.fullscreen =
      message: 'Connecting to Octoblu...'
      spinner: true

    @scope.showLog = false
    @scope.isInstalled = @GatebluServiceManager.isInstalled()

    @scope.getInstallerLink = (version='latest') =>
      baseUrl = "https://s3-us-west-2.amazonaws.com/gateblu/gateblu-ui/#{version}"
      if process.platform == 'darwin'
        filename = 'Gateblu.dmg'

      if process.platform == 'win32'
        filename = "gateblu-win32-#{process.arch}.exe"

      "#{baseUrl}/#{filename}"

    @scope.showMainLog = (device) =>
      @scope.showLog = true
      @scope.logTitle = 'Gateblu Log'
      @scope.logLines = @LogService.all()

    @scope.listenToDevice = (device) =>
      @GatebluServiceManager.getLogForDevice device.uuid

    @scope.hardRestartGateblu = =>
      alert = @mdDialog.confirm
        title: 'Hard Restart Gateblu'
        content: 'This will stop gateblu service, remove the devices and modules cache, then start gateblu. It will take a few minutes to redownload and configure the devices.'
        ok: 'Hard Restart'
        cancel: 'Cancel'
        theme: 'warning'

      @mdDialog
        .show alert
        .then =>
          @GatebluServiceManager.hardRestartGateblu (error) =>
            @scope.showError error if error?

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

    @scope.startService = =>
      @scope.fullscreen =
        message: "Starting Service..."
        spinner: true
        waitForConfig: true
      @GatebluServiceManager.startService (error) =>
        @LogService.add error if error?

    @scope.stopService = =>
      @scope.fullscreen =
        message: "Stopping Service..."
        spinner: true
        waitForConfig: true
      @GatebluServiceManager.stopService (error) =>
        @LogService.add error if error?

    @scope.toggleInfo = =>
      @scope.showInfo = !@scope.showInfo

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

    @scope.$watch 'deviceUuids', (deviceUuids) =>
      _.each deviceUuids, (uuid) =>
        @GatebluServiceManager.getLogForDevice uuid

angular.module 'gateblu-ui'
  .controller 'MainController', ($rootScope, $scope, $timeout, $interval, GatebluServiceManager, LogService, DeviceLogService, UpdateService, GatebluBackendInstallerService, GatebluService, DeviceManagerService, $mdDialog) ->
    new MainController
      rootScope: $rootScope
      scope: $scope
      timeout: $timeout
      interval: $interval
      mdDialog: $mdDialog
      GatebluServiceManager: GatebluServiceManager
      LogService: LogService
      DeviceLogService: DeviceLogService
      UpdateService: UpdateService
      GatebluBackendInstallerService: GatebluBackendInstallerService
      GatebluService: GatebluService
      DeviceManagerService: DeviceManagerService
