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

    @LogService.add 'Starting up!', 'info'

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
      @LogService.add "Gateblu Connected", 'info'
      @scope.fullscreen =
        message: 'Loading Devices...'
        spinner: true

    @rootScope.$on 'gateblu:claim', ($event) =>
      @GatebluServiceManager.generateSessionToken (error, result) =>
        return @rootScope.$broadcast 'error', error if error?
        shell.openExternal "https://app.octoblu.com/node-wizard/claim/#{result.uuid}/#{result.token}"

    @rootScope.$on 'gateblu:config', ($event, config) =>
      @LogService.add 'Gateblu Config Changed', 'info'
      @scope.gatebluConfig = config
      @scope.fullscreen = null if @scope.fullscreen?.waitForConfig
      unless config.owner?
        @scope.fullscreen =
          buttonTitle: 'Claim Gateblu'
          eventName: 'gateblu:claim'
          claiming: true
          menu: true

    @rootScope.$on 'gateblu:device:config', ($event, config) =>
      device = _.findWhere @scope.devices, uuid: config.uuid
      return unless device?
      device.online = config.online
      device.name = config.name

    @rootScope.$on 'gateblu:notReady', ($event, config) =>
      @LogService.add "Meshblu Authentication Failed", 'error'
      @scope.fullscreen =
        message: 'Meshblu Authentication Failed'

    @rootScope.$on "gateblu:disconnected", ($event) =>
      @LogService.add "Gateblu Disconnected", 'warning'
      @scope.fullscreen =
        message: 'Reconnecting to Octoblu...'
        spinner: true

    @rootScope.$on 'gateblu:refreshDevices', ($event, data={}) =>
      @LogService.add 'Refreshing Devices', 'info'
      @scope.deviceUuids = data.deviceUuids
      return if @showNoDevices data.deviceUuids
      @scope.fullscreen =
        message: 'Loading Devices...'
        spinner: true

    @rootScope.$on 'gateblu:devices', ($event, devices) =>
      @LogService.add 'Received Device List', 'info'
      @scope.devices = _.map devices, @updateDevice
      uuids = _.pluck @scope.devices, 'uuid'
      if _.isEqual uuids, @scope.deviceUuids
        @scope.fullscreen = null

    @rootScope.$on "device:unregistering", ($event, device) =>
      @fullscreen =
        message: 'Deleting Device...'
        spinner: true

    @rootScope.$on "device:unregistered", ($event, device) =>
      msg = "#{device.name} (~#{device.uuid}) has been deleted"
      @DeviceLogService.add device.uuid, 'warning', msg
      @LogService.add msg, 'warning'
      @fullscreen = null

    @rootScope.$on 'log:open:device', ($event, device) =>
      @scope.showLog = true
      @scope.logTitle = "Device Log (~#{device.uuid})"
      @scope.showingLogForDevice = device.uuid
      @scope.logLines = @DeviceLogService.get device.uuid

    @rootScope.$on 'log:close', ($event) =>
      @scope.showLog = false
      @scope.showingLogForDevice = null

    @rootScope.$on 'error', ($event, error) =>
      @scope.showError error

  showNoDevices: (uuids) =>
    showNoDevices = _.isEmpty(uuids) && !@scope.fullscreen?.claiming
    return true unless showNoDevices
    @scope.fullscreen =
      message: 'No Devices'
      menu: true
      spinner: false

  setupScope: =>
    @scope.fullscreen =
      message: 'Connecting to Octoblu...'
      spinner: true

    @scope.showingLogForDevice = null
    @scope.showLog = false
    @scope.isInstalled = @GatebluServiceManager.isInstalled()
    @scope.deviceLogs = {}

    @DeviceLogService.listen (uuid, msg) =>
      @scope.logLines = @DeviceLogService.get uuid if @scope.showingLogForDevice == uuid

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
          @fullscreen =
            message : 'Restarting Gateblu'
            spinner: true
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
          @fullscreen =
            message : 'Resetting Gateblu'
            spinner: true
          @GatebluServiceManager.resetGateblu (error) =>
            @scope.showError error if error?
            @scope.promptToClose() unless error?
            @rootScope.$apply()

    @scope.promptToClose = =>
      alert = @mdDialog.alert
        title: 'Close Gateblu'
        content: "Please quit Gateblu and reopen."
        ok: 'Okay'
        theme: 'warning'

      @mdDialog
        .show alert
        .then =>
          @fullscreen =
            message: 'Close Application'

    @scope.showError = (error) =>
      try
        errorMessage = error.toString()
      catch
        errorMessage = JSON.stringify error
      @LogService.add errorMessage, 'error'
      alert = @mdDialog.alert
        title: 'Error'
        content: errorMessage
        ok: 'Okay'
        theme: 'warning'

      @mdDialog
        .show alert

    @scope.startService = =>
      @scope.fullscreen =
        message: "Starting Service..."
        spinner: true
        waitForConfig: true
      @GatebluServiceManager.stopAndStartService (error) =>
        @LogService.add error, 'error' if error?

    @scope.stopService = =>
      @scope.fullscreen =
        message: "Stopping Service..."
        spinner: true
        waitForConfig: true
      @GatebluServiceManager.stopService (error) =>
        @LogService.add error, 'error' if error?

    @scope.toggleInfo = =>
      @scope.showInfo = !@scope.showInfo

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
