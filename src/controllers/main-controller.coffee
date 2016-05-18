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
    @ConfigService = dependencies.ConfigService
    @DeviceManagerService = dependencies.DeviceManagerService
    @mdDialog = dependencies.mdDialog
    @interval = dependencies.interval

    @LogService.add 'Starting up!', 'info'

    @setupScope()

    missingCallback = =>
      @scope.fullscreen =
        message: 'Missing Configuration. Will retry in 10 seconds.'
        spinner: false
        noTimeout: true

    foundCallback = =>
      @ConfigService.reset()
      @clearFullscreen()
      @setupRootScope()
      @checkVersions()

      @interval =>
        @checkVersions()
      , 1000 * 60 * 10

      @GatebluServiceManager.whoami (error, data) =>
        @scope.gateblu = data unless error?

    @ConfigService.waitForMeshbluConfig {seconds: 30, missingCallback, foundCallback}

  updateDevice: (device) =>
    filename = device.type?.replace ':', '/'
    device.icon_url = "https://icons.octoblu.com/#{filename}.svg"
    device.background = '#f5f5f5'
    device.col_span ?= 1
    device.row_span ?= 1
    if device.online == false
      device.background = '#e5e5e5'

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

    @rootScope.$on 'gateblu:claim', ($event) =>
      @GatebluServiceManager.generateSessionToken (error, result) =>
        return @rootScope.$broadcast 'error', error if error?
        shell.openExternal "https://app.octoblu.com/node-wizard/claim/#{result.uuid}/#{result.token}"

    @rootScope.$on 'gateblu:config', ($event, config) =>
      @LogService.add 'Gateblu Config Changed', 'info'
      @configChange?(config)
      @scope.gatebluConfig = config
      @showScreens()

    @rootScope.$on 'gateblu:config:update', ($event, config) =>
      @GatebluServiceManager.updateGatebluConfig config, (error) =>
        return @rootScope.$broadcast 'error', error if error?
        @waitForConfig 'online', true, =>
          @scope.promptToClose()

    @rootScope.$on 'gateblu:device:config', ($event, config) =>
      device = _.findWhere @scope.devices, uuid: config.uuid
      return unless device?
      _.extend device, config

    @rootScope.$on 'gateblu:notReady', ($event, config) =>
      @LogService.add "Meshblu Authentication Failed", 'error'
      @scope.fullscreen =
        message: 'Meshblu Authentication Failed'

    @rootScope.$on "gateblu:disconnected", ($event) =>
      @LogService.add "Gateblu Disconnected", 'warning'
      @scope.fullscreen =
        message: 'Reconnecting to Octoblu...'
        spinner: true

    @rootScope.$on 'gateblu:devices', ($event, devices=[]) =>
      @LogService.add 'Received Device List', 'info'
      @scope.devices = _.map devices, @updateDevice
      @clearFullscreen()

    @rootScope.$on "device:unregistering", ($event, device) =>
      @fullscreen =
        message: 'Deleting Device...'
        spinner: true

    @rootScope.$on "device:unregistered", ($event, device) =>
      msg = "#{device.name} (~#{device.uuid}) has been deleted"
      @DeviceLogService.add device.uuid, 'warning', msg
      @LogService.add msg, 'warning'
      @clearFullscreen()

    @rootScope.$on 'log:open:device', ($event, device) =>
      uuid = device.uuid[0..7]
      @scope.showLog = true
      @scope.logTitle = "\"#{device.name}\" Log (~#{uuid}...)" if device.name?
      @scope.logTitle = "Device Log (~#{uuid}...)" unless device.name?
      @scope.showingLogForDevice = device.uuid
      @scope.logLines = @DeviceLogService.get device.uuid

    @rootScope.$on 'log:device:add', ($event, entry) =>
      @scope.logLines = @DeviceLogService.get entry.uuid if @scope.showingLogForDevice == entry.uuid

    @rootScope.$on 'log:close', ($event) =>
      @scope.showLog = false
      @scope.showingLogForDevice = null

    @rootScope.$on 'log:clear:device', ($event, uuid) =>
      @DeviceLogService.clear uuid
      @scope.logLines = []

    @rootScope.$on 'log:clear', ($event) =>
      @LogService.clear()
      @scope.logLines = []

    @rootScope.$on 'error', ($event, error) =>
      @scope.showError error

    @rootScope.$on 'prompt-to-close', ($event) =>
      @scope.promptToClose()

  showScreens: =>
    uuids = _.pluck @scope.devices, 'uuid'
    unless @scope.gatebluConfig?.uuid?
      @scope.fullscreen =
        message: 'Initializing...'
        spinner: true
      return

    unless @scope.gatebluConfig?.owner?
      @scope.fullscreen =
        buttonTitle: 'Claim Gateblu'
        eventName: 'gateblu:claim'
        claiming: true
        noTimeout: true
        menu: true
      return

    if _.isEmpty @scope.devices
      message = 'No Devices'
      if !_.isEmpty @scope.gatebluConfig.devices
        message = 'No Devices (May be Loading...)'
      @scope.fullscreen =
        message: message
        menu: true
        spinner: false
        noTimeout: true
      return

    @clearFullscreen()

  clearFullscreen: =>
    @scope.fullscreen = null

  waitForConfig: (key, value, callback=->) =>
    @configChange = (config) =>
      return callback() if config[key] == value

  setupScope: =>
    @scope.fullscreen =
      message: 'Connecting to Octoblu...'
      spinner: true
      noTimeout: true

    @scope.showingLogForDevice = null
    @scope.showLog = false
    @scope.isInstalled = @GatebluServiceManager.isInstalled()
    @scope.deviceLogs = {}
    @scope.devices = []
    @scope.deviceUuids = []

    @scope.getInstallerLink = (version='latest') =>
      baseUrl = "https://s3-us-west-2.amazonaws.com/gateblu/gateblu-ui/#{version}"
      if process.platform == 'darwin'
        filename = 'Gateblu.dmg'

      if process.platform == 'win32'
        filename = "GatebluApp-win32-#{process.arch}.msi"

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

          @scope.fullscreen =
            message: 'Restarting Gateblu'
            spinner: true

          @waitForConfig 'online', true, =>
            @clearFullscreen()

          @GatebluServiceManager.hardRestartGateblu (error) =>
            @scope.showError error if error?
            @rootScope.$apply()

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
          @scope.fullscreen =
            message : 'Resetting Gateblu'
            spinner: true

          @waitForConfig 'online', true, =>
            @scope.promptToClose() unless error?

          @GatebluServiceManager.resetGateblu (error) =>
            @scope.showError error if error?
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

      @waitForConfig 'online', true, =>
        @clearFullscreen()

      @GatebluServiceManager.stopAndStartService (error) =>
        @LogService.add error, 'error' if error?

    @scope.stopService = =>
      @scope.fullscreen =
        message: "Stopping Service..."
        spinner: true
        waitForConfig: true

      @waitForConfig 'online', false, =>
        @clearFullscreen()

      @GatebluServiceManager.stopService (error) =>
        @LogService.add error, 'error' if error?

    @scope.toggleInfo = =>
      @scope.showInfo = !@scope.showInfo

    @scope.hideChangeNoticeAction = =>
      @scope.hideChangeNotice = true

    @scope.$watch 'fullscreen', =>
      # return clearTimeout @fullScreenTimeout unless @scope.fullscreen?
      # return clearTimeout @fullScreenTimeout if @scope.fullscreen.noTimeout
      # @fullScreenTimeout = @timeout @clearFullscreen, 30000

    @scope.$watch 'devices', =>
      @showScreens()

angular.module 'gateblu-ui'
  .controller 'MainController', ($rootScope, $scope, $timeout, $interval, GatebluServiceManager, ConfigService, LogService, DeviceLogService, UpdateService, GatebluBackendInstallerService, GatebluService, DeviceManagerService, $mdDialog) ->
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
      ConfigService: ConfigService
