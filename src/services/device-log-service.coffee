angular.module 'gateblu-ui'
  .service 'DeviceLogService', ->
    logs = {}
    _callbacks = []
    add: (uuid, type, log)=>
      message = log
      message = JSON.stringify(log).toString() unless _.isString log
      logs[uuid] ?= []
      entry = type: type, message: message, timestamp: new Date(), rawMessage: log
      logs[uuid].unshift entry
      _.each _callbacks, (callback) => callback uuid, entry
    get: (uuid) => logs[uuid]
    all: => logs
    clear: => logs[uuid] = []
    clearAll: => logs = {}
    listen: (callback=->)=>
      _callbacks.push callback
