class LogController
  constructor: (dependencies={}) ->
    @scope = dependencies.scope
    @rootScope = dependencies.rootScope

    @scope.closeLog = =>
      @rootScope.$broadcast 'log:close'

    @scope.clearLog = =>
      @rootScope.$broadcast 'log:clear:device', @scope.deviceUuid if @scope.deviceUuid?
      @rootScope.$broadcast 'log:clear' unless @scope.deviceUuid?

angular.module 'gateblu-ui'
  .controller 'LogController', ($scope, $rootScope) ->
    new LogController
      scope: $scope
      rootScope: $rootScope
