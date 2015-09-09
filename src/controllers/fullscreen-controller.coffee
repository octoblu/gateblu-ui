angular.module 'gateblu-ui'
  .controller 'FullscreenController', ($rootScope, $scope) ->
    $scope.broadcast = (eventName) =>
      $rootScope.$broadcast eventName
