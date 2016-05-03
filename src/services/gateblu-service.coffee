_ = require 'lodash'
Gateblu = require 'gateblu'

class GatebluService
  constructor: (dependencies={}) ->
    @rootScope = dependencies.rootScope
    @http = dependencies.http
    @ConfigService = dependencies.ConfigService
    @DeviceLogService = dependencies.DeviceLogService
    @DeviceManagerService = dependencies.DeviceManagerService

  start: =>
    @ConfigService.reset()
    meshbluConfig = _.clone @ConfigService.meshbluConfig
    meshbluConfig.auto_set_online = false

    @gateblu = new Gateblu meshbluConfig, @DeviceManagerService

    @gateblu.on 'error', (error) =>
      @broadcast 'error', error if error?

    @gateblu.on 'ready', =>
      @broadcast 'gateblu:connected'
      @gateblu.whoami (error, config) =>
        return @broadcast 'error', error if error?
        @broadcast 'gateblu:config', config

    @gateblu.on 'config', (config) =>
      @broadcast 'gateblu:config', config
      @broadcast 'gateblu:refreshDevices', deviceUuids: _.pluck config.devices, 'uuid'

    @gateblu.on 'refreshDevices', (data) =>
      @broadcast 'gateblu:refreshDevices', data

    @gateblu.on 'disconnected', (error) =>
      @broadcast 'gateblu:disconnected', error

    @gateblu.on 'notReady', (error) =>
      @broadcast 'gateblu:notReady', error

    @gateblu.on 'device:config', (config) =>
      @broadcast 'gateblu:device:config', config

    @gateblu.on 'message', @onMessage

    @gateblu.on 'device:message', (message) =>
      @broadcast 'gateblu:device:message', message

  whenConfigExists: (callback=->) =>
    return callback() if @ConfigService.meshbluConfigExists()
    _.delay @whenConfigExists, 2000, callback

  onMessage: (message) =>
    @broadcast 'gateblu:message', message
    {payload, topic} = message
    return if topic != 'gateblu_log'
    @DeviceLogService.addGatebluLogMessage payload

  broadcast: (event, data) =>
    @rootScope.$broadcast event, data
    @rootScope.$apply()

angular.module 'gateblu-ui'
  .service 'GatebluService', ($rootScope, $http, ConfigService, DeviceManagerService, DeviceLogService) ->
    gatebluService = new GatebluService
      rootScope: $rootScope
      http: $http
      ConfigService: ConfigService
      DeviceLogService: DeviceLogService
      DeviceManagerService: DeviceManagerService

    gatebluService.whenConfigExists =>
      gatebluService.start()

    return gatebluService
