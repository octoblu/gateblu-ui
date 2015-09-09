MeshbluHttp = require 'meshblu-http'
async = require 'async'
path = require 'path'
debug = require('debug')('gateblu-ui:GatebluService')
fsExtra = require 'fs-extra'
{exec} = require 'child_process'

class GatebluServiceManager
  constructor: (dependencies={}) ->
    @rootScope = dependencies.rootScope
    @http = dependencies.http
    @LogService = dependencies.LogService
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

  stopAndStartService: (callback=->) =>
    @stopService (error) =>
      @startService (error) =>
        return callback error if error?
        callback()

  startService: (callback=->) =>
    @LogService.add "Starting Service", 'info'
    if process.platform == 'darwin'
      return exec '/bin/launchctl load /Library/LaunchAgents/com.octoblu.GatebluService.plist', (error, stdout, stdin) =>
        return callback error if error?
        callback()

    if process.platform == 'win32'
      return exec "start \"GatebluServiceTray\" \"#{PROGRAMFILES}\\Octoblu\\GatebluService\\GatebluServiceTray.exe\"", (error, stdout, stdin) =>
        return callback error if error?
        callback()

    callback new Error "Unsupported Operating System"

  stopService: (callback=->) =>
    @LogService.add "Stopping Service", 'info'
    if process.platform == 'darwin'
      return exec '/bin/launchctl unload /Library/LaunchAgents/com.octoblu.GatebluService.plist', (error, stdout, stdin) =>
        return callback error if error?
        callback()

    if process.platform == 'win32'
      return exec 'taskkill /IM GatebluServiceTray.exe', (error, stdout, stdin) =>
        return callback error if error?
        callback()

    callback new Error "Unsupported Operating System"

  removeDeviceAndTmp: (callback=->) =>
    directories = [
      @ConfigService.getSupportPath 'tmp'
      @ConfigService.getSupportPath 'devices'
    ]

    async.each directories, fsExtra.emptyDir, callback

  removeGatebluConfig: (callback=->)=>
    fsExtra.unlink @ConfigService.meshbluConfigFile, (error) =>
      callback()

  emit: (event, data) =>
    @rootScope.$broadcast event, data
    @rootScope.$apply()

  deleteDevice: (device) =>
    @meshbluHttp.unregister device, (error) =>
      return @emit 'error', error if error?
      @emit 'device:unregistered', device

  unregisterGateblu: (callback=->) =>
    @meshbluHttp.unregister @ConfigService.meshbluConfig, callback

  resetGateblu: (callback=->) =>
    @LogService.add 'Resetting Gateblu', 'warning'
    events = [
      (callback=->) => @stopService => callback()
      @unregisterGateblu
      @removeDeviceAndTmp
      @removeGatebluConfig
      (callback=->) => @startService => callback()
    ]
    async.series events, (error) =>
      @LogService.add 'Reset Gateblu', 'info'
      return callback error if error?
      callback()

  hardRestartGateblu: (callback=->) =>
    @LogService.add 'Hard restart Gateblu', 'warning'
    events = [
      (callback=->) => @stopService => callback()
      @removeDeviceAndTmp
      (callback=->) => @startService => callback()
    ]
    async.series events, (error) =>
      return callback error if error?
      @LogService.add 'Successfully restarted Gateblu', 'info'
      callback()

  generateSessionToken: (callback=->) =>
    uuid = @ConfigService.meshbluConfig.uuid
    @meshbluHttp.generateAndStoreToken uuid, (error, result) =>
      return callback error if error?
      callback null, result

  waitForLog: (path, callback=->) =>
    fsExtra.exists path, (exists) =>
      return _.delay @waitForLog, 1000, path, callback unless exists
      callback()

angular.module 'gateblu-ui'
  .service 'GatebluServiceManager', ($rootScope, $http, LogService, DeviceLogService, ConfigService) ->
    new GatebluServiceManager
      rootScope: $rootScope
      http: $http
      LogService: LogService
      DeviceLogService: DeviceLogService
      ConfigService: ConfigService
