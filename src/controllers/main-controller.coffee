angular.module 'gateblu-ui' 
  .controller 'MainController', ($scope, GatebluService, LogService, UpdateService) ->   
    LogService.add 'Starting up!'
    _       = require("lodash")
    version = require("./package.json").version
    
    UpdateService.check(version).then (updateAvailable) =>
      $scope.updateAvailable = updateAvailable

    $scope.toggleDevice = _.debounce((device) =>
      if device.online
        GatebluService.stopDevice device
      else
        GatebluService.startDevice device
    , 500, {leading: true, trailing: false})

    process.on "uncaughtException", (error) ->
      console.error error.message
      console.error error.stack
      LogService.add error.message

    $scope.$on "gateblu:config", ($event, config) ->
      LogService.add "Connected to Meshblu. UUID: #{config.uuid}"
      $scope.name = config.name || config.uuid

    $scope.$on "gateblu:update", ($event, devices) ->
      $scope.devices = devices

    $scope.$on "gateblu:device:start", ($event, device) ->
      # $("ul.devices li[data-uuid=" + device.uuid + "]").addClass "active"

    $scope.$on 'gateblu:device:status', ($event, data) ->
      LogService.add(data)
      device = _.findWhere $scope.devices, {uuid: data.uuid}
      if device
        device.online = data.online

    $scope.$on "gateblu:refresh", ($event) ->
      LogService.add "Refreshing Device List"

    $scope.$on "gateblu:stderr", ($event, data, device) ->
      LogService.add "Error: #{device.name}"
      LogService.add data

    $scope.$on "gateblu:stdout", ($event, data, device) ->
      LogService.add device.name
      LogService.add data


