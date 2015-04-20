ipc = require 'ipc'
$ = require 'jquery'

sendIpcMessage = (message, callback) ->
  ipc.send( 'asynchronous-message',
    message,
    (response) =>
     callback response.error, response.message
  )

externalLink = ->
  restrict: 'C'
  link: (scope, element, attrs) =>
      $(element).click (event) =>
        event.preventDefault()
        sendIpcMessage topic: 'external-link', link: attrs.href

angular.module('gateblu-ui').directive "externalLink", externalLink
