
class DeviceManagerService
  constructor: (dependencies={}) ->
    @rootScope = dependencies.rootScope
    @devices = []

  addDevice: (device, callback=->) =>
    console.log 'addDevice', device?.uuid
    @devices.push device
    @broadcast()
    callback()

  broadcast: =>
    @rootScope.$broadcast 'gateblu:devices', @devices
    @rootScope.$apply()

  removeDevice: (device, callback=->) =>
    console.log 'removeDevice', device.uuid
    _.pull @devices, device
    @broadcast()
    callback()

  startDevice : (device, callback=->) =>
    console.log 'startDevice', device.uuid
    callback()

  stopDevice: (device, callback=->) =>
    console.log 'stopDevice', device.uuid
    callback()

angular.module 'gateblu-ui'
  .service 'DeviceManagerService', ($rootScope) ->
    new DeviceManagerService
      rootScope: $rootScope
