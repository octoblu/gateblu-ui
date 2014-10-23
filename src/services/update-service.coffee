angular.module 'gateblu-ui' 
  .service 'UpdateService', (LogService, $http)->

    check : (version) =>
      $http.get("http://gateblu.octoblu.com/version.json").then (response) =>
        response.data.version > version
