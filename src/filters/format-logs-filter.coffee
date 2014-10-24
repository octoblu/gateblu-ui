angular.module 'gateblu-ui'
  .filter "formatLogs", ->
    _ = require 'lodash'

    stringify = (line) ->
      message = line.message

      unless _.isString message
        message = JSON.stringify(message).toString()

      "#{line.timestamp} - #{message}"
      

    (lines) ->
      _.map(lines, stringify).join '\n'
