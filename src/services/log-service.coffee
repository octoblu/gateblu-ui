angular.module 'gateblu-ui' 
  .service 'LogService', ->
    logs = []
    add : (log)=> 
      logs.unshift({message: log, timestamp: new Date()})
    all : => 
      logs
    clear : =>
      logs.length = 0
