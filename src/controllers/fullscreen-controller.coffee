angular.module 'gateblu-ui'
  .controller 'FullscreenController', ($rootScope, $scope) ->
    $scope.broadcast = (eventName) =>
      console.log "broadcasting event #{eventName}"
      $rootScope.$broadcast eventName
