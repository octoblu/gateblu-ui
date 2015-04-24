meshblu = require 'meshblu'
async = require 'async'
angular.module 'gateblu-ui'
  .service 'GatebluService', ($q, $rootScope, $location) ->
    class GatebluService
      constructor : ->
        @config = require './meshblu.json'
        @skynetConnection = meshblu.createConnection
          uuid: @config.uuid
          token: @config.token
          server: @config.server
          port: @config.port

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

        _.each eventsToForward, (event) =>
          @skynetConnection.on event, (data) =>
            console.log event, data
            $rootScope.$broadcast event, data
            $rootScope.$apply()

        @skynetConnection.on 'ready',  () =>
          @skynetConnection.whoami {}, (gateblu) =>
            console.log 'ready', gateblu
            $rootScope.$broadcast 'gateblu:config', gateblu
            @subscribeToDevices gateblu.devices
            @updateDevices gateblu.devices

        @skynetConnection.on 'config', (data) =>
          console.log 'config', data
          if data.uuid == @config.uuid
            @subscribeToDevices data.devices
            @updateDevices data.devices
            return @emit 'gateblu:config', data

          return @emit 'gateblu:device:config', @updateIcon data

        @skynetConnection.on 'message', (data) =>
          console.log 'message', data
          if data.topic == 'device-status'
            @emit 'gateblu:device:status', uuid: data.fromUuid, online: data.payload.online             

      emit: (event, data) =>
        console.log 'emitting', event, data
        $rootScope.$broadcast event, data
        $rootScope.$apply()

      sendToGateway: (message, callback=->) =>
        @skynetConnection.message(_.extend(devices: @config.uuid, message), callback)

      subscribeToDevices: (devices) =>
        _.each devices, (device) =>
          console.log 'subscribing to device', device
          @skynetConnection.subscribe device, (res) =>
            console.log 'subscribe', device.uuid, res


      updateIcons : (devices) =>
        devices = _.map devices, @updateIcon
        $rootScope.$broadcast 'gateblu:update', devices
        $rootScope.$apply()

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
        @sendToGateway { topic: 'device-delete', args: [device.uuid, device.token]}, callback

      stopDevices : (callback=->) =>
        @sendToGateway { topic: 'devices-stop', args: []}, callback

      refreshGateblu: =>
        console.log 'sending refresh event'
        @sendToGateway topic: 'refresh'

      updateDevices: (devices) =>
        async.map devices, @updateDevice, (error, devices) =>
          @updateIcons _.compact devices if devices.length

      updateDevice: (device, callback) =>
        @skynetConnection.devices _.pick( device, 'uuid', 'token'), (results) =>
           console.log 'updateDevice results', results.devices
           return callback null, null unless results.devices?
           callback null, _.extend({}, results.devices[0], device)

    gatebluService = new GatebluService
