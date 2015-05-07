meshblu = require 'meshblu'
async = require 'async'
path = require 'path'
debug = require('debug')('gateblu-ui:GatebluService')
fs = require 'fs-extra'

class GatebluService
  EVENTS_TO_FORWARD = [
    'gateblu:config'
    'gateblu:orig:config'
    'gateblu:device:start'
    'gateblu:device:status'
    'gateblu:device:config'
    'gateblu:refresh'
    'gateblu:stderr'
    'gateblu:stdout'
    'gateblu:npm:stdout'
    'gateblu:npm:stderr'
    'gateblu:unregistered'
    'gateblu:disconnected'
  ]

  constructor: (dependencies={}) ->
    @rootScope = dependencies.rootScope

  createMeshbluConnection: (callback=->)=>
    @loadConfig (error, config) =>
      if error?
        console.error "Error", error
        return @emit 'gateblu:error', error.message if error?
      callback null, meshblu.createConnection config

  isInstalled: =>
    fs.existsSync @getConfigPath()

  getInstallerLink: =>
    baseUrl = 'https://s3-us-west-2.amazonaws.com/gateblu/gateblu-service/latest'
    if process.platform == 'darwin'
      filename = 'GatebluService.pkg'

    if process.platform == 'win32'
      filename = "GatebluService-win32-#{process.arch}.msi"

    "#{baseUrl}/#{filename}"

  start: =>
    if @isInstalled()
      return @startMeshbluConnection()

    startupInterval = setInterval =>
      if @isInstalled()
        clearInterval startupInterval
        @startMeshbluConnection()
    , 5000

  startMeshbluConnection: =>
    @createMeshbluConnection (error, @meshbluConnection) =>
      _.each @EVENTS_TO_FORWARD, (event) =>
        @meshbluConnection.on event, (data) =>
          console.log event, data
          @emit event, data

      @meshbluConnection.on 'ready',  () =>
        console.log 'ready'
        @meshbluConnection.whoami {}, (gateblu) =>
          console.log 'ready', gateblu
          @uuid = gateblu.uuid
          @emit 'gateblu:config', gateblu
          @handleDevices gateblu.devices
          @refreshGateblu()

      @meshbluConnection.on 'notReady', (data) =>
        console.log 'notReady', data
        @emit 'gateblu:notReady'

      @meshbluConnection.on 'config', (data) =>
        console.log 'config', data
        if data.uuid == @uuid
          @handleDevices data.devices
          return @emit 'gateblu:config', data

        return @emit 'gateblu:device:config', @updateIcon data

      @meshbluConnection.on 'message', (data) =>
        console.log 'message', data
        if data.topic == 'device-status'
          @emit 'gateblu:device:status', uuid: data.fromUuid, online: data.payload.online

  getConfigPath: =>
    if process.platform == 'darwin'
      return "#{process.env.HOME}/Library/Application Support/GatebluService/meshblu.json"

    if process.platform == 'win32'
      return "#{process.env.LOCALAPPDATA}\\Octoblu\\GatebluService\\meshblu.json"

    return './meshblu.json'

  loadConfig: (callback=->) =>
    configFile = @getConfigPath()

    fs.exists configFile, (exists) =>
      callback new Error('meshblu.json does not exist') unless exists
      config = {}

      try
        callback null, require configFile
      catch e
        callback e

  emit: (event, data) =>
    console.log 'emitting', event, data
    @rootScope.$broadcast event, data
    @rootScope.$apply()

  handleDevices: (devices) =>
    devices ?= []
    @subscribeToDevices devices
    @updateDevices devices

  sendToGateway: (message, callback=->) =>
    newMessage = _.extend devices: [@uuid], message
    @meshbluConnection.message newMessage, callback

  subscribeToDevices: (devices) =>
    _.each devices, (device) =>
      console.log 'subscribing to device', device
      @meshbluConnection.subscribe device, (res) =>
        console.log 'subscribe', device.uuid, res

  updateIcons : (devices) =>
    devices = _.map devices, @updateIcon
    @emit 'gateblu:update', devices

  updateIcon: (device) =>
    filename = device.type.replace ':', '/'
    device.icon_url = "https://ds78apnml6was.cloudfront.net/#{filename}.svg"
    return device

  stopDevice : (device, callback=->) =>
    @sendToGateway { topic: 'device-stop', deviceUuid: device.uuid }

  startDevice : (device, callback=->) =>
    console.log 'starting device', device
    @sendToGateway { topic: 'device-start', payload: device }

  deleteDevice : (device, callback=->) =>
    @emit 'gateblu:unregistered', device
    @sendToGateway { topic: 'device-delete', deviceUuid: device.uuid, deviceToken: device.token }
    callback()

  stopDevices : (callback=->) =>
    @sendToGateway { topic: 'devices-stop', args: []}, callback

  refreshGateblu: =>
    console.log 'sending refresh event'
    @sendToGateway topic: 'refresh'

  updateDevices: (devices) =>
    async.map devices, @updateDevice, (error, devices) =>
      @updateIcons _.compact devices

  updateDevice: (device, callback) =>
    console.log 'before device merge', device
    @meshbluConnection.devices _.pick( device, 'uuid', 'token'), (results) =>
       console.log 'updateDevice results', results.devices
       return callback null, null unless results.devices?
       callback null, _.extend({}, device, results.devices[0])

angular.module 'gateblu-ui'
  .service 'GatebluService', ($rootScope) ->
    gatebluService = new GatebluService rootScope: $rootScope
    gatebluService.start()
    gatebluService
