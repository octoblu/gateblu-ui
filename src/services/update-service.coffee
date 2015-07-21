_ = require 'lodash'
request = require 'request'
cmp = require 'semver-compare'
fs    = require 'fs'
path  = require 'path'

angular.module 'gateblu-ui'
  .service 'UpdateService', (LogService, GatebluService, $http) ->
    service =
      checkService : (version, callback=->) =>
        request.get 'https://registry.npmjs.org/gateblu-forever', json: true, (error, response, body) =>
          return callback error unless body?
          updateAvailable = cmp(body['dist-tags'].latest, version) > 0
          callback error, updateAvailable

      checkUI : (version, callback=->) =>
        request.get 'https://registry.npmjs.org/gateblu-ui', json: true, (error, response, body) =>
          return callback error unless body?
          updateAvailable = cmp(body['dist-tags'].latest, version) > 0
          callback error, updateAvailable

      checkServiceVersion : (callback=->) =>
        GatebluService.getVersion (error, version) =>
          return callback error if error?
          service.checkService version, (error, updateAvailable) =>
            callback error, updateAvailable, version

      checkUiVersion : (callback=->) =>
        fs.readFile path.resolve('./package.json'), (error, config) =>
          return callback error if error?
          try
            config = JSON.parse config
          catch error
            return callback error

          service.checkUI config.version, (error, updateAvailable) =>
            callback error, updateAvailable, config.version
    service
