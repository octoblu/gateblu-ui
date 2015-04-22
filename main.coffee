app = require 'app'
BrowserWindow = require 'browser-window'
DeviceManager = require 'gateblu-forever'
Gateblu = require 'gateblu'
configManager = require './configManager'
_ = require 'lodash'
ipc = require 'ipc'
shell = require 'shell'

meshbluJSON = configManager.loadConfig()
unless meshbluJSON
  configManager.saveConfig()
  meshbluJSON = configManager.loadConfig()

mainWindow = null

gatebluEvents = [
  'gateblu:config'
  'gateblu:orig:config'
  'refresh'
  'update'
  'device:start'
  'device:status'
  'device:config'
  'refresh'
  'stderr'
  'stdout'
  'unregistered'
  'disconnected'
]

deviceManagerEvents = [
  'npm:stdout'
  'npm:stderr'
]

app.on 'window-all-closed', ->
  if process.platform != 'darwin'
    app.quit()

initializeGateway = =>
  deviceManager = new DeviceManager(meshbluJSON)
  gateblu = new Gateblu meshbluJSON, deviceManager

  gateblu.on 'gateblu:config', (config) =>
    configManager.saveConfig config
        
  _.each gatebluEvents, (event) =>
    gateblu.on event, (data) =>
      console.log 'gatebluEvents', event, data
      event = "gateblu:#{event}" unless event.indexOf('gateblu:') == 0
      mainWindow.webContents.send event, data

  _.each deviceManagerEvents, (event) =>
    deviceManager.on event, (data) =>
      console.log 'deviceManagerEvents', event, data
      mainWindow.webContents.send "gateblu:#{event}", data

  ipc.on 'asynchronous-message', (event, message) =>
    return unless message.topic?
    return if message.topic == 'refresh'
    return shell.openExternal(message.link) if message.topic == 'external-link'
    return mainWindow.toggleDevTools() if message.topic == 'dev-tools'

    args = message.args
    args.push (error, response) =>
      console.log "#{message.topic} response:", response
      event.sender.send 'asynchronous-response', {error: error, message: response}

    gateblu[message.topic].apply gateblu, args if gateblu[message.topic]?

app.on 'ready', ->
  mainWindow = new BrowserWindow(width: 800, height: 600)

  ipc.on 'asynchronous-message', (event, message) ->
    console.log 'event', event
    console.log 'message', message
    return unless message.topic == 'refresh'
    initializeGateway()

  mainWindow.loadUrl 'file://' + __dirname + '/index.html'

  mainWindow.on 'closed', ->
    mainWindow = null

app.on 'window-all-closed', ->
  app.quit()
