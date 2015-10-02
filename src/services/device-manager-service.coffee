class DeviceManagerService
  constructor: (dependencies={}) ->
    @rootScope = dependencies.rootScope
    @devices = []

  addDevice: (device, callback=->) =>
    @devices.push device
    @broadcast()
    callback()

  broadcast: =>
    @devices = _.uniq @devices, 'uuid'
    @rootScope.$emit 'gateblu:devices', @devices
    @rootScope.$apply()

  removeDevice: (device, callback=->) =>
    _.pull @devices, device
    @broadcast()
    callback()

  startDevice : (device, callback=->) =>
    callback()

  stopDevice: (device, callback=->) =>
    callback()

angular.module 'gateblu-ui'
  .service 'DeviceManagerService', ($rootScope) ->
    new DeviceManagerService
      rootScope: $rootScope
