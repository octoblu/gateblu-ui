_ = require 'lodash'
request = require 'request'
cmp = require 'semver-compare'

angular.module 'gateblu-ui'
  .service 'UpdateService', (LogService, $http)->

    checkService : (version, callback=->) =>
      request.get 'https://registry.npmjs.org/gateblu-forever', json: true, (error, response, body) =>
        updateAvailable = cmp(body['dist-tags'].latest, version) > 0
        callback error, updateAvailable

    checkUI : (version, callback=->) =>
      request.get 'https://registry.npmjs.org/gateblu-ui', json: true, (error, response, body) =>
        updateAvailable = cmp(body['dist-tags'].latest, version) > 0
        callback error, updateAvailable
