ipc = require('ipc')

angular.module 'gateblu-ui'
  .service 'GatebluService', ($q, $rootScope, $location) ->
    class GatebluService
      init: () =>
        eventsToForward = [
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
          'gateblu:unconfigured'
          'gateblu:disconnected'
        ]
        ipc.removeAllListeners()

        _.each eventsToForward, (event) =>
          ipc.on event, (data) =>
            console.log event, data
            $rootScope.$broadcast event, data
            $rootScope.$apply()

        ipc.on "update", (devices) ->
          _.each devices, (device) =>
            filename = device.type.replace ':', '/'
            device.icon_url = "https://ds78apnml6was.cloudfront.net/#{filename}.svg"

          $rootScope.$broadcast 'gateblu:update', devices
          $rootScope.$apply()

     stopDevice : (device, callback=->) =>
       ipc.stopDevice device.uuid, callback

     startDevice : (device, callback=->) =>
       @gateblu.startDevice device, callback

     deleteDevice : (device, callback=->) =>
       @gateblu.deleteDevice device.uuid, device.token, callback

     stopDevices : (callback=->) =>
       @gateblu.stopDevices callback
    gatebluService = new GatebluService
    gatebluService.init()
    gatebluService
    # init = =>
    #   config = configManager.loadConfig()
    #   unless config
    #     configManager.saveConfig()
    #     config = configManager.loadConfig()
    #
    #   ipc = new DeviceManager(config)
    #   @gateblu = new Gateblu(config, @deviceManager)
    #
    #   pathSep = ':'
    #   platformPath = 'node-v0.10.35-linux-x64'
    #
    #   if process.platform == 'win32'
    #     platformPath = 'node-v0.10.35-win-x86'
    #     pathSep = ';'
    #   else if process.platform == 'darwin'
    #     platformPath = 'node-v0.10.35-darwin-x64'
    #
    #   process.env.PATH = path.join(process.cwd(), 'dist', platformPath, 'bin') + pathSep + process.env.PATH
    #
    #   process.on 'exit', (error) =>
    #     console.error 'exit', error
    #     @gateblu.cleanup()
    #
    #   process.on 'SIGINT', (error) =>
    #     console.error 'SIGINT', error
    #     @gateblu.cleanup()
    #
    #   process.on 'uncaughtException', (error) =>
    #     console.error 'uncaughtException'
    #     console.error error.message
    #     console.error error.stack
    #     @gateblu.cleanup()
    #

    return gatebluService
