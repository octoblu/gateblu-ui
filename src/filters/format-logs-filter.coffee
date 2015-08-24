angular.module 'gateblu-ui'
  .filter "formatLogs", ->
    stringify = (line) ->
      message = line.message

      unless _.isString message
        try
          message = JSON.stringify(message).toString()
        catch

      "#{line.timestamp} - #{message}"


    (lines) ->
      _.map(lines, stringify).join '\n'
