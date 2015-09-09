async = require 'async'

class GatebluBackendInstallerService
  constructor : (@dependencies={})->

  install: (callback=->) =>
    callback()

angular.module 'gateblu-ui'
  .service 'GatebluBackendInstallerService', ($q, $rootScope, $location) ->
    new GatebluBackendInstallerService $q: $q, $rootscope: $rootScope, $location: $location
