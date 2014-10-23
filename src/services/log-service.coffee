angular.module 'gateblu-ui' 
  .service 'LogService', ->
    logs = []
    add : (log)=> 
      logs.push(log)
    all : => 
      logs
    clear : =>
      logs.length = 0
