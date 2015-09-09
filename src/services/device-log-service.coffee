class DeviceLogService
  constructor: ($rootScope) ->
    @logs = {}
    @rootScope = $rootScope

  add: (uuid, type, log) =>
    message = log
    try
      message = JSON.stringify(log).toString() unless _.isString log

    @logs[uuid] ?= []
    entry =
      type: type
      message: message
      timestamp: new Date()
      uuid: uuid
      rawMessage: log
    @rootScope.$broadcast 'log:device:add', entry
    @logs[uuid].unshift entry

  get: (uuid) => @logs[uuid]
  clear: (uuid) => @logs[uuid] = []
  clearAll: => @logs = {}

angular.module 'gateblu-ui'
  .service 'DeviceLogService', ($rootScope)->
    return new DeviceLogService $rootScope
