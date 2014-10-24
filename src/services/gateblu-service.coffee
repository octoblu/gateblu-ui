angular.module 'gateblu-ui' 
  .service 'GatebluService', ($rootScope)->   
    configManager = require './src/config-manager'
    rimraf        = require 'rimraf'
    fs            = require 'fs-extra'
    _             = require 'lodash'
    config        = configManager.loadConfig()

    unless config
      configManager.saveConfig()
      config = configManager.loadConfig()

    rimraf.sync config.path + "/dist"
    fs.copySync "dist", config.path + "/dist"

    Gateblu = require("gateblu")
    gateblu = new Gateblu(config)

    process.on('exit', gateblu.cleanup)
    process.on('SIGINT', gateblu.cleanup)
    process.on('uncaughtException', gateblu.cleanup)

    gateblu.on 'gateblu:config', (config) =>
      configManager.saveConfig config
      $rootScope.$broadcast 'gateblu:config', config
      $rootScope.$apply()

    gateblu.on "update", (devices) ->
      _.each devices, (device) =>
        filename = device.type.replace ':', '/'
        device.icon_url = "https://ds78apnml6was.cloudfront.net/#{filename}.svg"

      $rootScope.$broadcast 'gateblu:update', devices
      $rootScope.$apply()

    gateblu.on "device:start", (device) ->
      $rootScope.$broadcast 'gateblu:device:start', device
      $rootScope.$apply()

    gateblu.on "device:status", (data) ->
      $rootScope.$broadcast 'gateblu:device:status', data
      $rootScope.$apply()

    gateblu.on "device:config", (data) ->
      $rootScope.$broadcast 'gateblu:device:config', data
      $rootScope.$apply()

    gateblu.on "refresh", ->
      $rootScope.$broadcast 'gateblu:refresh'
      $rootScope.$apply()

    gateblu.on "stderr", (data, device) ->
      $rootScope.$broadcast 'gateblu:stderr', data, device
      $rootScope.$apply()

    gateblu.on "stdout", (data, device) ->
      $rootScope.$broadcast 'gateblu:stdout', data, device
      $rootScope.$apply()


    # send this back
    stopDevice: (device) =>
      gateblu.stopDevice(device.uuid)
    startDevice: (device) =>
      gateblu.startDevice(device)
