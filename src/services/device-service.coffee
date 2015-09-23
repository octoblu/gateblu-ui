MeshbluHttp = require 'meshblu-http'

class DeviceService
  constructor: (dependencies={}) ->
    @rootScope = dependencies.rootScope
    @ConfigService = dependencies.ConfigService
    @meshbluHttp = new MeshbluHttp @ConfigService.meshbluConfig
    @devices = []

  updateDangerously: (uuid, query, callback=->) =>
    return console.log 'invalid query' unless query
    @meshbluHttp.updateDangerously uuid, query, callback

angular.module 'gateblu-ui'
  .service 'DeviceService', ($rootScope, ConfigService) ->
    new DeviceService
      rootScope: $rootScope
      ConfigService: ConfigService
