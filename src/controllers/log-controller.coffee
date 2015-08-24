class LogController
  constructor: (dependencies={}) ->
    @scope = dependencies.scope
    @rootScope = dependencies.rootScope

    @scope.closeLog = =>
      @rootScope.$broadcast 'log:close'

angular.module 'gateblu-ui'
  .controller 'LogController', ($scope, $rootScope) ->
    new LogController
      scope: $scope
      rootScope: $rootScope
