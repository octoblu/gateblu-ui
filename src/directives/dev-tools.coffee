ipc = require 'ipc'
$ = require 'jquery'

sendIpcMessage = (message, callback) ->
  ipc.send( 'asynchronous-message',
    message,
    (response) =>
     callback response.error, response.message
  )

devTools = ->
  restrict: 'C'
  link: (scope, element, attrs) =>
      $(element).click (event) =>
        event.preventDefault()
        sendIpcMessage topic: 'dev-tools', link: attrs.href

angular.module('gateblu-ui').directive "devTools", devTools
