MeshbluHttp = require 'meshblu-http'
async = require 'async'
path = require 'path'
debug = require('debug')('gateblu-ui:GatebluService')
fsExtra = require 'fs-extra'
{exec} = require 'child_process'
{Tail} = require 'tail'

class GatebluServiceManager
  constructor: (dependencies={}) ->
    @rootScope = dependencies.rootScope
    @http = dependencies.http
    @DeviceLogService = dependencies.DeviceLogService
    @ConfigService = dependencies.ConfigService
    @meshbluHttp = new MeshbluHttp @ConfigService.meshbluConfig

  whoami: (callback=->)=>
    @meshbluHttp.whoami (error, data) =>
      return callback error if error?
      callback null, data

  isInstalled: =>
    ! _.isEmpty @ConfigService.servicePackageJson

  getInstallerLink: (version='latest') =>
    baseUrl = "https://s3-us-west-2.amazonaws.com/gateblu/gateblu-service/#{version}"
    if process.platform == 'darwin'
      filename = 'GatebluService.pkg'

    if process.platform == 'win32'
      filename = "GatebluService-win32-#{process.arch}.msi"

    "#{baseUrl}/#{filename}"

  getSupportPath: (fileOrPath) =>
    if process.platform == 'darwin'
      return "#{process.env.HOME}/Library/Application Support/GatebluService/#{fileOrPath}"

    if process.platform == 'win32'
      return "#{process.env.LOCALAPPDATA}\\Octoblu\\GatebluService\\#{fileOrPath}"

    return "./#{filePath}"

  getConfigPath: =>
    @getSupportPath "meshblu.json"

  startService: (callback=->) =>
    if process.platform == 'darwin'
      return exec '/bin/launchctl load /Library/LaunchAgents/com.octoblu.GatebluService.plist', (error, stdout, stdin) =>
        return callback error
        callback()

    if process.platform == 'win32'
      return exec "start \"GatebluServiceTray\" \"#{PROGRAMFILES}\\Octoblu\\GatebluService\\GatebluServiceTray.exe\"", (error, stdout, stdin) =>
        return callback error
        callback()

    callback new Error "Unsupported Operating System"

  stopService: (callback=->) =>
    if process.platform == 'darwin'
      return exec '/bin/launchctl unload /Library/LaunchAgents/com.octoblu.GatebluService.plist', (error, stdout, stdin) =>
        return callback error
        callback()

    if process.platform == 'win32'
      return exec 'taskkill /IM GatebluServiceTray.exe', (error, stdout, stdin) =>
        return callback error
        callback()

    callback new Error "Unsupported Operating System"

  removeDeviceAndTmp: (callback=->) =>
    directories = [
      @ConfigService.getSupportPath 'tmp'
      @ConfigService.getSupportPath 'devices'
    ]

    async.each directories, fsExtra.emptyDir, callback

  removeGatebluConfig: (callback=->)=>
    configPath = @getConfigPath()
    fsExtra.unlink configPath, (error) =>
      callback()

  emit: (event, data) =>
    @rootScope.$broadcast event, data
    @rootScope.$apply()

  deleteDevice: (device, callback=->) =>
    @emit 'gateblu:unregistered', device

    @meshbluHttp.unregister device, (error) =>
      return callback error if error?

      # this forces a refresh of the devices array
      @stopDevice device, callback

  resetGateblu: (callback=->) =>
    events = [
      @stopService
      @unregisterGateblu
      @removeDeviceAndTmp
      @removeGatebluConfig
    ]
    async.series events, (error) =>
      return callback error if error?
      callback()

  hardRestartGateblu: (callback=->) =>
    events = [
      @stopService
      @removeDeviceAndTmp
      @startService
    ]
    async.series events, (error) =>
      return callback error if error?
      callback()

  generateSessionToken: (callback=->) =>
      uuid = @ConfigService.meshbluConfig.uuid
      @meshbluHttp.generateAndStoreToken uuid, (error, result) =>
        return callback error if error?
        callback null, result

  waitForLog: (uuid, callback=->) =>
    filePath = @ConfigService.getSupportPath "devices/#{uuid}/meshblu.json"
    fsExtra.exists filePath, (exists) =>
      return _.delay @waitForLog, 1000, uuid, callback unless exists
      callback()

  getLogForDevice: (uuid, lineCallback=->) =>
    @meshbluConnection.subscribe uuid: uuid
    @waitForLog uuid, =>
      outLog = new Tail(@ConfigService.getSupportPath("devices/#{uuid}/forever.stdout"));
      outLog.on "line", (line) =>
        @DeviceLogService.add uuid, "info", line

      errLog = new Tail(@ConfigService.getSupportPath("devices/#{uuid}/forever.stderr"));
      errLog.on "line", (line) =>
        @DeviceLogService.add uuid, "error", line

angular.module 'gateblu-ui'
  .service 'GatebluServiceManager', ($rootScope, $http, DeviceLogService, ConfigService) ->
    new GatebluServiceManager
      rootScope: $rootScope
      http: $http
      DeviceLogService: DeviceLogService
      ConfigService: ConfigService
