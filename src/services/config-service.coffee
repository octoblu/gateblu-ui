fs = require 'fs-extra'
jsonfile = require 'jsonfile'

PROGRAMFILES = process.env['PROGRAMFILES(X86)'] || process.env['PROGRAMFILES']

class ConfigService
  constructor: (dependencies={}) ->
    @reset()

  reset: =>
    @servicePackageJson = @loadServicePackageJson()
    @uiPackageJson = @loadUIPackageJson()
    @meshbluConfig = @loadMeshbluConfig()

  loadMeshbluConfig: =>
    jsonfile.readFileSync @getSupportPath 'meshblu.json', throws: false

  loadServicePackageJson: =>
    jsonfile.readFileSync @getServicePackagePath(), throws: false

  loadUIPackageJson: =>
    filename = path.resolve __dirname + '/package.json'
    jsonfile.readFileSync filename, throws: false

  getSupportPath: (fileOrPath) =>
    if process.platform == 'darwin'
      return "#{process.env.HOME}/Library/Application Support/GatebluService/#{fileOrPath}"

    if process.platform == 'win32'
      return "#{process.env.LOCALAPPDATA}\\Octoblu\\GatebluService\\#{fileOrPath}"

    return "./#{filePath}"

  getServicePackagePath: =>
    if process.platform == 'darwin'
      return "#{@getServiceDir()}/package.json"

    if process.platform == 'win32'
      return "#{@getServiceDir()}\\package.json"

    return "#{@getServiceDir()}/package.json"

  getServiceDir: =>
    if process.platform == 'darwin'
      return "/Library/Octoblu/GatebluService"

    if process.platform == 'win32'
      return "#{PROGRAMFILES}\\Octoblu\\GatebluService"

    return '.'

angular.module 'gateblu-ui'
  .service 'ConfigService', ->
    new ConfigService
