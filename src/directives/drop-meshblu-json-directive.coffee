angular.module 'gateblu-ui'
.directive 'dropMeshbluJson', ->
  restrict: 'A'
  link: (scope, element) ->
    holder = element[0]
    holder.ondragover = -> false
    holder.ondragleave =  -> false
    holder.ondragend = -> false
    holder.ondrop = (event) ->
      event.preventDefault()
      event.stopPropagation()

      file = event.dataTransfer.files[0]
      item = event.dataTransfer.items[0]

      return getFromFile file, onData if file?
      getFromData item, onData

    onData = (error, data) =>
      console.log 'data', data

    getFromData = (item, callback) =>
      item.getAsString (rawMeshbluJson) =>
        callback null, JSON.parse rawMeshbluJson

    getFromFile = (file, callback) =>
      fileReader = new FileReader()
      fileReader.addEventListener 'load', (event) ->
        callback null, JSON.parse event.target.result
      fileReader.readAsText file
