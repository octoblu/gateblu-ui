angular.module 'gateblu-ui'
  .service 'LogService', ->
    logs = []
    add : (log, type)=>
      message = log
      unless _.isString log
        try
          message = JSON.stringify(log).toString()

      logs.unshift type: type, message: message, timestamp: new Date(), rawMessage: log

    all : =>
      logs
    clear : =>
      logs = []
