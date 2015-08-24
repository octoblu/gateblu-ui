angular.module 'gateblu-ui'
  .service 'LogService', ->
    logs = []
    add : (log)=>
      message = log
      unless _.isString log
        try
          message = JSON.stringify(log).toString()
        catch

      logs.unshift message: message, timestamp: new Date(), rawMessage: log

    all : =>
      logs
    clear : =>
      logs.length = 0
