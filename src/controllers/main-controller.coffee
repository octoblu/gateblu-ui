_ = require 'lodash'

angular.module 'gateblu-ui'
  .controller 'MainController', ($scope, GatebluService, LogService, UpdateService) ->
    LogService.add 'Starting up!'
    console.log 'starting gateblu'
    GatebluService.refreshGateblu()
    version = 'change me'
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
    $scope.connected = false

    UpdateService.check(version).then (updateAvailable) =>
      $scope.updateAvailable = updateAvailable

    $scope.toggleDevice = _.debounce((device) =>
      if device.online
        GatebluService.stopDevice device
      else
        GatebluService.startDevice device
    , 500, {leading: true, trailing: false})

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

    $scope.showDevice = (device) =>
      sweetAlert
        title: device.name
        text: device.uuid
        type: 'info'
        confirmButtonColor: '#428bca'

    $scope.$on "gateblu:config", ($event, config) =>
      $scope.connected = true
      #gui.App.setCrashDumpDir config.crashPath
      LogService.add "Gateway ~#{config.uuid} is online"
      $scope.gateblu = config

    $scope.$on "gateblu:disconnected", ($event) =>
      $scope.connected = false
      LogService.add "Disconnected..."
      GatebluService.stopDevices()

    $scope.$on "gateblu:update", ($event, devices) ->
      $scope.devices = devices
      $scope.lucky_robot_url = undefined
      if _.isEmpty devices
        $scope.lucky_robot_url = _.sample robotUrls

    $scope.$on "gateblu:device:start", ($event, device) ->
      # $("ul.devices li[data-uuid=" + device.uuid + "]").addClass "active"

    $scope.$on 'gateblu:device:status', ($event, data) ->
      device = _.findWhere $scope.devices, uuid: data.uuid
      return unless device
      LogService.add "#{device.name} ~#{device.uuid} is #{if data.online then 'online' else 'offline'}"
      device.online = data.online

    $scope.$on 'gateblu:device:config', ($event, device) ->
      $scope.devices =  _.reject $scope.devices, {uuid: device.uuid}
      $scope.devices.push device
      LogService.add "#{device.name} ~#{device.uuid} has been updated"

    $scope.$on "gateblu:refresh", ($event) ->
      LogService.add "Refreshing Device List"

    $scope.$on "gateblu:stderr", ($event, data, device) ->
      LogService.add data
      LogService.add "Error: #{device.name}"

    $scope.$on "gateblu:stdout", ($event, data, device) ->
      console.log device.name, device.uuid, data

    $scope.$on "gateblu:npm:stderr", ($event, stderr) ->
      LogService.add stderr
      LogService.add "Error: npm install"

    $scope.$on "gateblu:npm:stdout", ($event, stdout) ->
      console.log stdout
      console.log "npm install"

    $scope.$on "gateblu:unregistered", ($event, device) ->
      msg = "#{device.name} (~#{device.uuid}) has been deleted"
      LogService.add msg
      sweetAlert
        title: 'Deleted'
        text: msg
        type: 'success'
        confirmButtonColor: '#428bca'
