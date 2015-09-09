_ = require 'lodash'
Gateblu = require 'gateblu'
Meshblu = require 'meshblu'

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
    @listenForLogEvents meshbluConfig

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

    @gateblu.on 'refreshDevices', (data) =>
      @broadcast 'gateblu:refreshDevices', data

    @gateblu.on 'disconnected', (error) =>
      @broadcast 'gateblu:disconnected', error

    @gateblu.on 'notReady', (error) =>
      @broadcast 'gateblu:notReady', error

    @gateblu.on 'device:config', (config) =>
      @broadcast 'gateblu:device:config', config

    @gateblu.on 'message', (message) =>
      @broadcast 'gateblu:message', message

    @gateblu.on 'device:message', (message) =>
      @broadcast 'gateblu:device:message', message

  whenConfigExists: (callback=->) =>
    return callback() if @ConfigService.meshbluConfigExists()
    _.delay @whenConfigExists, 2000, callback

  listenForLogEvents: (meshbluConfig) =>
    return
    # console.log 'meshbluConfig:' + JSON.stringify(meshbluConfig,null,2)
    # @meshblu = Meshblu.createConnection meshbluConfig
    # # subscribeOptions = uuid: meshbluConfig.uuid, token: meshbluConfig.token, types: ['received']
    # subscribeOptions = uuid: meshbluConfig.uuid, token: meshbluConfig.token, types: ['sent'], topic: ['*log*']
    # console.log 'subscribeOptions:' + JSON.stringify(subscribeOptions,null,2)
    #
    # @meshblu.subscribe subscribeOptions, (result) =>
    #   console.log 'got a subscribe event!' + JSON.stringify(result,null,2)
      # return @broadcast 'error', result?.error?.message if result?.error?


    # @meshblu.on 'message', (message) =>
    #   {payload} = message
    #   console.log 'device log: ' + JSON.stringify payload
    #   return console.log 'no payload' unless payload?
    #   @DeviceLogService.add payload.deviceUuid, payload.workflow, payload.message

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

    gatebluService
