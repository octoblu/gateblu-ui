angular.module 'gateblu-ui' 
  .controller 'LogController', ($scope, LogService) ->   
    $scope.logs = LogService.all()
