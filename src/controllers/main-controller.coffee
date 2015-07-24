_     = require 'lodash'
shell = require 'shell'

angular.module 'gateblu-ui'
  .controller 'MainController', ($scope, $timeout, GatebluService, LogService, DeviceLogService, UpdateService, GatebluBackendInstallerService, $mdDialog) ->
    LogService.add 'Starting up!'
    $scope.getInstallerLink = =>
      baseUrl = 'https://s3-us-west-2.amazonaws.com/gateblu/gateblu-ui/latest'
      if process.platform == 'darwin'
        filename = 'Gateblu.dmg'

      if process.platform == 'win32'
        filename = "gateblu-win32-#{process.arch}.zip"

      "#{baseUrl}/#{filename}"

    colors = ['#b9f6ca', '#ffff8d', '#84ffff', '#80d8ff', '#448aff', '#b388ff', '#8c9eff', '#ff8a80', '#ff80ab']
    robotUrls = [
      './images/robot1.png'
      './images/robot2.png'
      './images/robot3.png'
      './images/robot4.png'
      './images/robot5.png'
      './images/robot6.png'
      './images/robot7.png'
      './images/robot8.png'
      './images/robot9.png'
    ]
    $scope.devices = []
    $scope.connected = false
    $scope.isInstalled = GatebluService.isInstalled()
    $scope.serviceInstallerLink = GatebluService.getInstallerLink()
    $scope.uiInstallerLink = $scope.getInstallerLink()

    checkVersions = =>
      UpdateService.checkServiceVersion (error, serviceUpdateAvailable, serviceVersion) =>
        return console.error error if error?
        UpdateService.checkUiVersion (error, uiUpdateAvailable, uiVersion) =>
          return console.error error if error?
          $timeout =>
            $scope.serviceVersion = serviceVersion
            $scope.uiVersion = uiVersion
            $scope.serviceUpdateAvailable = serviceUpdateAvailable
            $scope.uiUpdateAvailable = uiUpdateAvailable
            _.delay checkVersions, 5000
          , 0

    checkVersions()

    $scope.toggleDevice = _.debounce((device) =>
      if device.online
        GatebluService.stopDevice device
      else
        GatebluService.startDevice device
    , 500, {leading: true, trailing: false})

    $scope.deleteDevice = (device) =>
      alert = $mdDialog.confirm
        title: 'Are you sure?'
        content: "This will remove #{device.name} ~#{device.uuid}"
        ok: 'Delete'
        cancel: 'Cancel'
        theme: 'confirm'

      $mdDialog
        .show alert
        .then ->
          GatebluService.deleteDevice device

    $scope.listenToDevice = (device) =>
      GatebluService.getLogForDevice device.uuid

    $scope.toggleDeviceLog = (uuid) =>
      return $scope.showLogForDevice = null if !_.isEmpty $scope.showLogForDevice
      $scope.showLogForDevice = uuid;

    $scope.showDevice = (device) =>
      alert = $mdDialog.confirm
        title: device.name
        content: device.uuid
        theme: 'info'
        cancel: 'Close'
        ok: 'Show Logs'

      $mdDialog
        .show alert
        .then =>
          alert = undefined
          $scope.toggleDeviceLog device.uuid
        .catch =>
          alert = undefined

    $scope.$on "gateblu:config", ($event, config) =>
      $scope.connected = true
      LogService.add "Gateway ~#{config.uuid} config changed"
      $scope.gateblu = config

    $scope.$on "gateblu:disconnected", ($event) =>
      $scope.connected = false
      LogService.add "Disconnected"
      GatebluService.stopDevices()

    $scope.$on "gateblu:update", ($event, devices) ->
      $scope.handleDevices devices

    $scope.claimGateblu = =>
      GatebluService.generateSessionToken (error, result) =>
        shell.openExternal "https://app.octoblu.com/node-wizard/claim/#{result.uuid}/#{result.token}"

    $scope.hardRestartGateblu = =>
      alert = $mdDialog.confirm
        title: 'Hard Restart Gateblu'
        content: 'This will stop gateblu service, remove the devices and modules cache, then start gateblu. It will take a few minutes to redownload and configure the devices.'
        ok: 'Hard Restart'
        cancel: 'Cancel'
        theme: 'warning'

      $scope.serviceChanging = true

      $mdDialog
        .show alert
        .then =>
          GatebluService.hardRestartGateblu (error) =>
            $timeout =>
              $scope.serviceChanging = false
            , 1000
            $scope.showError error if error?
        .catch =>
          $scope.serviceChanging = false

    $scope.resetGateblu = =>
      alert = $mdDialog.confirm
        title: 'Reset Gateblu'
        content: 'Do you want to reset your Gateblu? This will unregister it from your account and remove all your things.'
        ok: 'Reset'
        cancel: 'Cancel'
        theme: 'warning'

      $mdDialog
        .show alert
        .then =>
          $scope.handleDevices []
          GatebluService.resetGateblu (error) =>
            $scope.showError error if error?

    $scope.showError = (error) =>
      alert = $mdDialog.alert
        title: 'Error'
        content: if error?.message then error.message else error
        ok: 'Okay'
        theme: 'info'

      $mdDialog
        .show alert

    $scope.toggleService = ->
      $scope.serviceChanging = true
      if $scope.serviceStopped
        GatebluService.startService (error) =>
          LogService.add error if error?
          $timeout =>
            $scope.serviceChanging = false
            $scope.serviceStopped = false
          , 1000
      else
        GatebluService.stopService (error) =>
          LogService.add error if error?
          $timeout =>
            $scope.serviceChanging = false
            $scope.serviceStopped = true
          , 1000

    $scope.updateDevice = (device) ->
      foundDevice = _.findWhere $scope.devices, uuid: device.uuid
      if foundDevice?
        foundDevice.colorInt ?= parseInt(device.uuid[0..6], 16) % colors.length
        foundDevice.background = colors[foundDevice.colorInt]
        foundDevice.col_span ?= 1
        foundDevice.row_span ?= 1
        if device.online == false
          foundDevice.background = '#f5f5f5'

        $timeout =>
          _.extend foundDevice, device
        , 0

    $scope.handleDevices = (devices) ->
      devicesToDelete = _.filter $scope.devices, (device) =>
        ! _.findWhere devices, uuid: device.uuid

      devicesToAdd = _.filter devices, (device) =>
        ! _.findWhere $scope.devices, uuid: device.uuid

      _.each devicesToDelete, (device) ->
        _.remove $scope.devices, uuid: device.uuid

      _.each devicesToAdd, (device) ->
        $scope.listenToDevice(device);
        $scope.devices.push device

      _.map devices, (device) ->
        $scope.updateDevice device


      $scope.lucky_robot_url = undefined
      if _.isEmpty devices
        $scope.lucky_robot_url = _.sample robotUrls

    $scope.$on "gateblu:device:start", ($event, device) ->
      DeviceLogService.add device.uuid, 'config', "Device start"
      # $("ul.devices li[data-uuid=" + device.uuid + "]").addClass "active"

    $scope.$on 'gateblu:device:status', ($event, data) ->
      device = _.findWhere $scope.devices, uuid: data.uuid
      return unless device
      LogService.add "#{device.name} ~#{device.uuid} is #{if data.online then 'online' else 'offline'}"
      device.online = data.online
      $scope.updateDevice device
      DeviceLogService.add device.uuid, 'config', "Device online"

    $scope.$on 'gateblu:device:config', ($event, device) ->
      $scope.updateDevice device
      LogService.add "#{device.name} ~#{device.uuid} has been updated"
      DeviceLogService.add device.uuid, 'config', "Device updated"

    $scope.$on "gateblu:refresh", ($event) ->
      LogService.add "Refreshing Device List"

    $scope.$on "gateblu:stderr", ($event, data, device) ->
      DeviceLogService.add device.uuid, 'error', data

    $scope.$on "gateblu:stdout", ($event, data, device) ->
      DeviceLogService.add device.uuid, 'info', data

    $scope.$on "gateblu:npm:stderr", ($event, stderr) ->
      LogService.add stderr
      LogService.add "Error: npm install"

    $scope.$on "gateblu:npm:stdout", ($event, stdout) ->
      console.log stdout
      console.log "npm install"

    $scope.$on "gateblu:unregistered", ($event, device) ->
      msg = "#{device.name} (~#{device.uuid}) has been deleted"
      LogService.add msg
      alert = $mdDialog.alert
        title: 'Deleted'
        content: msg
        ok: 'Close'
        theme: 'info'

      $mdDialog
        .show alert
        .finally ->
          alert = undefined
