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
    @DeviceService = dependencies.DeviceService
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
      return exec 'taskkill /t /f /im GatebluServiceTray.exe', (error, stdout, stdin) =>
        return callback error if error?
        callback()

    callback new Error "Unsupported Operating System"

  deviceState : (device, state,  callback=->) =>
    events = [
      (callback) => @meshbluHttp.update device.uuid, {stop: !state}, callback
      (callback) => @stopService => callback()
      (callback) => @startService => callback()
    ]
    async.series events, (error) =>
      return callback error if error?
      callback()

  removeDeviceAndTmp: (callback=->) =>
    directories = [
      @ConfigService.getSupportPath 'tmp'
    ]

    async.each directories, fsExtra.emptyDir, callback

  removeGatebluConfig: (callback=->)=>
    @LogService.add 'Removing Gateblu Config', 'info'
    fsExtra.unlink @ConfigService.meshbluConfigFile, (error) =>
      callback()

  updateGatebluConfigFile: (config, callback=->)=>
    @LogService.add 'Updating Gateblu Config', 'info'
    fsExtra.writeJson @ConfigService.meshbluConfigFile, config, callback

  emit: (event, data) =>
    @rootScope.$broadcast event, data
    @rootScope.$apply()

  deleteDevice: (device) =>
    @meshbluHttp.unregister device, (error) =>
      return @emit 'error', error if error?
      @emit 'device:unregistered', device

  unregisterGateblu: (callback=->) =>
    @meshbluHttp.unregister @ConfigService.meshbluConfig, callback

  updateGatebluConfig: (config, callback=->) =>
    @LogService.add 'Update Gateblu Config', 'info'
    events = [
      (callback) => @stopService => callback()
      (callback) => @updateGatebluConfigFile config, callback
      (callback) => @startService => callback()
    ]
    async.series events, (error) =>
      @LogService.add 'Gateblu Config Updated', 'info'
      return callback error if error?
      callback()

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
