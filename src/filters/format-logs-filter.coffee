angular.module 'gateblu-ui'
  .filter "formatLogs", ->
    _ = require 'lodash'

    stringify = (line) ->
      return line if _.isString line
      JSON.stringify(line).toString()

    (lines) ->
      _.map(lines, stringify).join '\n'
