_  = require 'lodash'

class DeviceLogService
  constructor: ($rootScope) ->
    @logs = {}
    @rootScope = $rootScope
    @MAX_LOG_LINES = 100

  add: (uuid, type, log) =>
    message = log
    try message = JSON.stringify(log).toString() unless _.isString log

    entry =
      type: type
      message: message
      timestamp: new Date()
      uuid: uuid
      rawMessage: log
    @addRaw entry

  addGatebluLogMessage: (message) =>
    return unless message?
    return unless message.deviceUuid?

    type = switch message.state
      when 'stderr' then 'error'
      when 'stdout', 'stop' then 'debug'
      else 'info'

    entry =
      type: type
      message: message.message ? message.workflow
      timestamp: new Date()
      uuid: message.deviceUuid
      state: message.state
      rawMessage: message
    @addRaw entry

  addRaw: (entry) =>
    @logs[entry.uuid] ?= []
    @logs[entry.uuid].unshift entry
    @logs[entry.uuid] = _.take @logs[entry.uuid], @MAX_LOG_LINES
    @rootScope.$broadcast 'log:device:add', entry

  hasError: (uuid) =>
    return _.any @logs[uuid], type: 'error'

  get: (uuid) => @logs[uuid]
  clear: (uuid) => @logs[uuid] = []
  clearAll: => @logs = {}

angular.module 'gateblu-ui'
  .service 'DeviceLogService', ($rootScope)->
    return new DeviceLogService $rootScope
