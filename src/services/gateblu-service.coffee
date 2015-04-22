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
          'gateblu:unregistered'
          'gateblu:disconnected'
        ]

        ipc.removeAllListeners()

        _.each eventsToForward, (event) =>
          ipc.on event, (data) =>
            console.log event, data
            $rootScope.$broadcast event, data
            $rootScope.$apply()

        ipc.on "gateblu:update", (devices) =>
          console.log 'updating devices with', devices
          @updateIcons devices

      updateIcons : (devices) =>
        _.each devices, (device) =>
          filename = device.type.replace ':', '/'
          device.icon_url = "https://ds78apnml6was.cloudfront.net/#{filename}.svg"
        $rootScope.$broadcast 'gateblu:update', devices
        $rootScope.$apply()

      stopDevice : (device, callback=->) =>
        @sendIpcMessage { topic: 'stopDevice', args: [device.uuid]}, callback

      startDevice : (device, callback=->) =>
        @sendIpcMessage { topic: 'startDevice', args: [device]}, callback

      deleteDevice : (device, callback=->) =>
        @sendIpcMessage { topic: 'deleteDevice', args: [device.uuid, device.token]}, callback

      stopDevices : (callback=->) =>
        @sendIpcMessage { topic: 'stopDevices', args: []}, callback

      refreshGateblu: =>
        console.log 'sending refresh event'
        @sendIpcMessage topic: 'refresh'

      sendIpcMessage : (message, callback) =>
        ipc.send( 'asynchronous-message',
          message,
          (response) =>
           callback response.error, response.message
       )

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
