class Gateblu
  constructor: (@uuid, @token) ->
  start: =>
    

angular.module 'gateblu-ui'
  .constant 'Gateblu', Gateblu
