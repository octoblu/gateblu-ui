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
    @devices = [] unless _.isArray @devices
    @rootScope.$emit 'gateblu:devices', @devices
    @rootScope.$apply()

  removeDevice: (device, callback=->) =>
    @devices = _.reject @devices, { uuid: device.uuid }
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
