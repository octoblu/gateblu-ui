class DropMeshbluJson
  link: (@scope, element) =>
    holder = element[0]
    holder.ondragover = -> false
    holder.ondragleave =  -> false
    holder.ondragend = -> false
    holder.ondrop = (event) =>
      event.preventDefault()
      event.stopPropagation()

      file = event.dataTransfer.files[0]
      item = event.dataTransfer.items[0]

      return @getFromFile file, @onData if file?
      return @getFromData item, @onData if item?

  validate: (data) =>
    return false unless data?
    return false unless data.uuid?
    return false unless data.token?
    return true

  parseData: (rawData) =>
    try return JSON.parse rawData

  onData: (error, data) =>
    console.log 'data', data
    return @scope.$emit 'error', 'Invalid Meshblu Config' unless @validate data
    @scope.$emit 'gateblu:config:update', data

  getFromData: (item, callback) =>
    item.getAsString (rawMeshbluJson) =>
      callback null, @parseData rawMeshbluJson

  getFromFile: (file, callback) =>
    fileReader = new FileReader()
    fileReader.addEventListener 'load', (event) =>
      callback null, @parseData event.target.result
    fileReader.readAsText file

angular.module 'gateblu-ui'
.directive 'dropMeshbluJson', ->
  restrict: 'A'
  link: -> new DropMeshbluJson().link arguments...
