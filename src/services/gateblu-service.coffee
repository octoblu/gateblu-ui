_ = require 'lodash'
Gateblu = require 'gateblu'

class GatebluService
  constructor: (dependencies={}) ->
    @rootScope = dependencies.rootScope
    @http = dependencies.http
    @ConfigService = dependencies.ConfigService
    @DeviceManagerService = dependencies.DeviceManagerService

  start: =>
    meshbluConfig = _.clone @ConfigService.meshbluConfig
    meshbluConfig.auto_set_online = false

    @gateblu = new Gateblu meshbluConfig, @DeviceManagerService

    @gateblu.on 'error', (error) =>
      @broadcast 'error', error if error?

    @gateblu.on 'ready', =>
      @broadcast 'gateblu:connected'

    @gateblu.on 'gateblu:config', (config) =>
      @broadcast 'gateblu:config', config

    @gateblu.on 'notReady', (error) =>
      @broadcast 'gateblu:disconnected', error

  broadcast: (event, data) =>
    @rootScope.$broadcast event, data
    @rootScope.$apply()

angular.module 'gateblu-ui'
  .service 'GatebluService', ($rootScope, $http, ConfigService, DeviceManagerService) ->
    gatebluService = new GatebluService
      rootScope: $rootScope
      http: $http
      ConfigService: ConfigService
      DeviceManagerService: DeviceManagerService

    gatebluService.start()
    gatebluService
