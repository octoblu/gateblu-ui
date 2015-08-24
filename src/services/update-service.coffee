_ = require 'lodash'
request = require 'request'
cmp = require 'semver-compare'
fs    = require 'fs'
path  = require 'path'

class UpdateService
  constructor: (dependencies={}) ->
    @ConfigService = dependencies.ConfigService
    @LogService = dependencies.LogService
    @http = dependencies.http

  checkService: (version, callback=->) =>
    request.get 'https://registry.npmjs.org/gateblu-forever', json: true, (error, response, body) =>
      return callback error unless body?
      updateAvailable = cmp(body['dist-tags'].latest, version) > 0
      callback null, updateAvailable, body['dist-tags'].latest

  checkUI: (version, callback=->) =>
    request.get 'https://registry.npmjs.org/gateblu-ui', json: true, (error, response, body) =>
      return callback error unless body?
      updateAvailable = cmp(body['dist-tags'].latest, version) > 0
      callback null, updateAvailable, body['dist-tags'].latest

  checkServiceVersion: (callback=->) =>
    thisVersion = @ConfigService.servicePackageJson?.version
    @checkService thisVersion, (error, updateAvailable, newVersion) =>
      return callback error if error?
      callback null, updateAvailable, thisVersion, newVersion

  checkUiVersion: (callback=->) =>
    thisVersion = @ConfigService.uiPackageJson?.version
    @checkUI thisVersion, (error, updateAvailable, newVersion) =>
      return callback error if error?
      callback null, updateAvailable, thisVersion, newVersion

angular.module 'gateblu-ui'
  .service 'UpdateService', (LogService, ConfigService, $http) ->
    new UpdateService
      http: $http
      LogService: LogService
      ConfigService: ConfigService
