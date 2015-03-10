angular.module 'gateblu-ui'
  .service 'GatebluService', ($rootScope) ->
    configManager = require './src/config-manager'
    rimraf        = require 'rimraf'
    fs            = require 'fs-extra'
    _             = require 'lodash'
    path          = require 'path'
    DeviceManager = require 'gateblu-forever'
    Gateblu       = require 'gateblu'

    init = =>
      config = configManager.loadConfig()
      unless config
        configManager.saveConfig()
        config = configManager.loadConfig()

      @deviceManager = new DeviceManager(config)
      @gateblu = new Gateblu(config, @deviceManager)

      pathSep = ':'
      platformPath = 'node-v0.10.35-linux-x64'

      if process.platform == 'win32'
        platformPath = 'node-v0.10.35-win-x86'
        pathSep = ';'
      else if process.platform == 'darwin'
        platformPath = 'node-v0.10.35-darwin-x64'

      process.env.PATH += pathSep + path.join(process.cwd(), 'dist', platformPath, 'bin')

      process.on 'exit', (error) =>
        console.error 'exit', error
        @gateblu.cleanup()

      process.on 'SIGINT', (error) =>
        console.error 'SIGINT', error
        @gateblu.cleanup()

      process.on 'uncaughtException', (error) =>
        console.error 'uncaughtException'
        console.error error.message
        console.error error.stack
        @gateblu.cleanup()

      @gateblu.on 'gateblu:config', (config) =>
        configManager.saveConfig config
        $rootScope.$broadcast 'gateblu:config', config
        $rootScope.$apply()

      @gateblu.on 'gateblu:orig:config', (config) =>
        $rootScope.$broadcast 'gateblu:orig:config', config
        $rootScope.$apply()

      @gateblu.on "update", (devices) ->
        _.each devices, (device) =>
          filename = device.type.replace ':', '/'
          device.icon_url = "https://ds78apnml6was.cloudfront.net/#{filename}.svg"

        $rootScope.$broadcast 'gateblu:update', devices
        $rootScope.$apply()

      @gateblu.on "device:start", (device) ->
        $rootScope.$broadcast 'gateblu:device:start', device
        $rootScope.$apply()

      @gateblu.on "device:status", (data) ->
        $rootScope.$broadcast 'gateblu:device:status', data
        $rootScope.$apply()

      @gateblu.on "device:config", (data) ->
        $rootScope.$broadcast 'gateblu:device:config', data
        $rootScope.$apply()

      @gateblu.on "refresh", ->
        $rootScope.$broadcast 'gateblu:refresh'
        $rootScope.$apply()

      @gateblu.on "stderr", (data, device) ->
        $rootScope.$broadcast 'gateblu:stderr', data, device
        $rootScope.$apply()

      @gateblu.on "stdout", (data, device) ->
        $rootScope.$broadcast 'gateblu:stdout', data, device
        $rootScope.$apply()

      @deviceManager.on "npm:stderr", (stderr) ->
        $rootScope.$broadcast 'gateblu:npm:stderr', stderr
        $rootScope.$apply()

      @deviceManager.on "npm:stdout", (stdout) ->
        $rootScope.$broadcast 'gateblu:npm:stdout', stdout
        $rootScope.$apply()

      @gateblu.on "unregistered", =>
        @stopDevices =>
          @gateblu.removeAllListeners()

          config = configManager.loadConfig()
          delete config.uuid
          delete config.token
          configManager.saveConfig config
          init()

      @gateblu.on "disconnected", ->
        $rootScope.$broadcast 'gateblu:disconnected'
        $rootScope.$apply()


    init()
      # send this back
    @stopDevice = (device, callback=->) =>
      @gateblu.stopDevice device.uuid, callback

    @startDevice = (device, callback=->) =>
      @gateblu.startDevice device, callback

    @deleteDevice = (device, callback=->) =>
      @gateblu.deleteDevice device.uuid, device.token, callback

    @stopDevices = (callback=->) =>
      @gateblu.stopDevices callback

    return this
