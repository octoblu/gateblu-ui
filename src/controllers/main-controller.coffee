angular.module 'gateblu-ui'
  .controller 'MainController', ($scope, GatebluService, LogService, UpdateService) ->
    LogService.add 'Starting up!'
    _       = require("lodash")
    version = require("./package.json").version

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

    gui = require 'nw.gui'

    $scope.connected = false

    gui.Window.get().on 'close', ->
      win = this
      GatebluService.stopDevices ->
        win.close true

    getDevice = (uuid) =>
      _.findWhere $scope.devices, {uuid: uuid}

    UpdateService.check(version).then (updateAvailable) =>
      $scope.updateAvailable = updateAvailable

    $scope.toggleDevice = _.debounce((device) =>
      if device.online
        GatebluService.stopDevice device
      else
        GatebluService.startDevice device
    , 500, {leading: true, trailing: false})

    $scope.showDevConsole = =>
      gui.Window.get().showDevTools()

    $scope.downloadGateblu = =>
      gui.Shell.openExternal 'https://gateblu.octoblu.com'

    $scope.deleteDevice = (device) =>
      sweetAlert
        title: 'Are you sure?'
        text: "This will remove #{device.name} ~#{device.uuid}"
        type: 'warning'
        showCancelButton: true
        confirmButtonColor: '#d9534f'
        confirmButtonText: 'Delete'
        closeOnConfirm: false
      ,
        =>
          GatebluService.deleteDevice device
          LogService.add "#{device.name} ~#{device.uuid} has been deleted"
          sweetAlert
            title: 'Deleted'
            text: 'Your device has been deleted'
            type: 'success'
            confirmButtonColor: '#428bca'

    $scope.showDevice = (device) =>
      sweetAlert
        title: device.name
        text: device.uuid
        type: 'info'
        confirmButtonColor: '#428bca'

    process.on "uncaughtException", (error) ->
      console.error error.message
      console.error error.stack
      LogService.add error.message

    $scope.$on "gateblu:config", ($event, config) =>
      gui.App.setCrashDumpDir config.crashPath
      LogService.add "Gateway ~#{config.uuid} is online"
      $scope.gateblu = config

    $scope.$on "gateblu:disconnected", ($event) =>
      $scope.connected = false
      LogService.add "Disconnected..."
      GatebluService.stopDevices()

    $scope.$on "gateblu:orig:config", ($event, config) =>
      LogService.add "#{config.name} ~#{config.uuid} has been updated"
      $scope.gateblu = config

    $scope.$on "gateblu:update", ($event, devices) ->
      $scope.connected = true
      $scope.devices = devices
      $scope.lucky_robot_url = undefined
      if _.isEmpty devices
        $scope.lucky_robot_url = _.sample robotUrls

    $scope.$on "gateblu:device:start", ($event, device) ->
      # $("ul.devices li[data-uuid=" + device.uuid + "]").addClass "active"

    $scope.$on 'gateblu:device:status', ($event, data) ->
      device = getDevice(data.uuid)
      return unless device
      LogService.add "#{device.name} ~#{device.uuid} is #{if data.online then 'online' else 'offline'}"
      device.online = data.online

    $scope.$on 'gateblu:device:config', ($event, data) ->
      device = getDevice(data.uuid)
      return unless device
      LogService.add "#{device.name} ~#{device.uuid} has been updated"
      device.name = data.name

    $scope.$on "gateblu:refresh", ($event) ->
      LogService.add "Refreshing Device List"

    $scope.$on "gateblu:stderr", ($event, data, device) ->
      LogService.add "Error: #{device.name}"
      LogService.add data

    $scope.$on "gateblu:stdout", ($event, data, device) ->
      console.log device.name, device.uuid, data


