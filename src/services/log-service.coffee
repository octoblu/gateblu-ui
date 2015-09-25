_ = require 'lodash'

angular.module 'gateblu-ui'
  .service 'LogService', ->
    logs = []
    MAX_LOG_LINES = 100
    add : (log, type)=>
      message = log
      try message = JSON.stringify(log).toString() unless _.isString log
      logs.unshift type: type, message: message, timestamp: new Date(), rawMessage: log
      logs = _.take logs, MAX_LOG_LINES
    all : =>
      logs
    clear : =>
      logs = []
