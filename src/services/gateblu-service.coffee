meshblu = require 'meshblu'
async = require 'async'
path = require 'path'
debug = require('debug')('gateblu-ui:GatebluService')
fs = require 'fs-extra'
{exec} = require 'child_process'

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
      options = _.extend auto_set_online: false, config
      callback null, meshblu.createConnection options

  isInstalled: =>
    fs.existsSync(@getConfigPath()) &&
      fs.existsSync(@getPackagePath())

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
          @emit event, data

      @meshbluConnection.on 'ready',  () =>
        @meshbluConnection.whoami {}, (gateblu) =>
          console.log 'ready', gateblu
          @uuid = gateblu.uuid
          @emit 'gateblu:config', gateblu
          @handleDevices gateblu.devices
          @refreshGateblu()

      @meshbluConnection.on 'notReady', (data) =>
        console.log 'notReady', data
        @emit 'gateblu:notReady'

      @meshbluConnection.on 'unregister', (device) =>
        unless data.uuid == @uuid
          @meshbluConnection.whoami {}, (gateblu) =>
            @handleDevices gateblu.devices

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

  getPackagePath: =>
    if process.platform == 'darwin'
      return "/Library/Octoblu/GatebluService/package.json"

    if process.platform == 'win32'
      return "#{process.env['PROGRAMFILES(X86)']}\\Octoblu\\GatebluService\\package.json"

    return './meshblu.json'

  startService: (callback=->) =>
    if process.platform == 'darwin'
      exec '/bin/launchctl load /Library/LaunchAgents/com.octoblu.GatebluService.plist', (error, stdout, stdin) =>
        return callback error

    if process.platform == 'win32'
      exec "start \"GatebluServiceTray\" \"#{process.env['PROGRAMFILES(X86)']}\\Octoblu\\GatebluService\\GatebluServiceTray.exe\"", (error, stdout, stdin) =>
        return callback error

    callback new Error "Unsupported Operating System"

  stopService: (callback=->) =>
    if process.platform == 'darwin'
      exec '/bin/launchctl unload /Library/LaunchAgents/com.octoblu.GatebluService.plist', (error, stdout, stdin) =>
        return callback error

    if process.platform == 'win32'
      exec 'taskkill /IM GatebluServiceTray.exe', (error, stdout, stdin) =>
        return callback error

    callback new Error "Unsupported Operating System"

  loadConfig: (callback=->) =>
    configFile = @getConfigPath()

    fs.exists configFile, (exists) =>
      callback new Error('meshblu.json does not exist') unless exists
      config = {}

      try
        callback null, require configFile
      catch e
        callback e

  loadPackageJson: (callback=->) =>
    configFile = @getPackagePath()

    fs.exists configFile, (exists) =>
      callback new Error('package.json does not exist') unless exists
      config = {}

      console.log configFile

      try
        callback null, require configFile
      catch e
        callback e

  getVersion: (callback=->) =>
    @loadPackageJson (error, pkg) =>
      callback error, pkg?.version

  emit: (event, data) =>
    @rootScope.$broadcast event, data
    @rootScope.$apply()

  deviceExists: (device, callback) =>
    @meshbluConnection.device uuid: device.uuid, (result) ->
      callback !result?.error?

  handleDevices: (devices) =>
    devices ?= []
    async.filterSeries devices, @deviceExists, (devices) =>
      @subscribeToDevices devices
      @updateDevices devices

  updateGatewayDevice: (device, data, callback=->) =>
    @meshbluConnection.whoami {}, (gateblu) =>
      foundDevice = _.findWhere gateblu.devices, uuid: device.uuid
      _.extend foundDevice, data if foundDevice?

      @meshbluConnection.update gateblu, =>
        callback()

  sendToGateway: (message, callback=->) =>
    newMessage = _.extend devices: [@uuid], message
    @meshbluConnection.message newMessage, callback

  subscribeToDevices: (devices) =>
    _.each devices, (device) =>
      console.log 'subscribing to device', device
      @meshbluConnection.subscribe device, (res) ->
        console.log 'subscribe', device.uuid, res

  updateIcons : (devices) =>
    devices = _.map devices, @updateIcon
    @emit 'gateblu:update', devices

  updateIcon: (device) =>
    filename = device.type.replace ':', '/'
    device.icon_url = "https://ds78apnml6was.cloudfront.net/#{filename}.svg"
    return device

  stopDevice : (device, callback=->) =>
    @updateGatewayDevice device, stop: true, callback

  startDevice : (device, callback=->) =>
    @updateGatewayDevice device, stop: false, callback

  deleteDevice : (device, callback=->) =>
    @emit 'gateblu:unregistered', device
    @meshbluConnection.whoami {}, (gateblu) =>
      foundDevice = _.pull gateblu.devices, uuid: device.uuid

      return callback() unless foundDevice?

      @meshbluConnection.update gateblu, =>
        @meshbluConnection.unregister device
        @handleDevices gateblu.devices
        callback()

  refreshGateblu: =>
    @sendToGateway topic: 'refresh'

  updateDevices: (devices) =>
    async.map devices, @updateDevice, (error, devices) =>
      @updateIcons _.compact devices

  updateDevice: (device, callback) =>
    @meshbluConnection.devices _.pick(device, 'uuid', 'token'), (results) =>
       return callback null, null unless results.devices?
       callback null, _.extend({}, device, results.devices[0])

angular.module 'gateblu-ui'
  .service 'GatebluService', ($rootScope) ->
    gatebluService = new GatebluService rootScope: $rootScope
    gatebluService.start()
    gatebluService
