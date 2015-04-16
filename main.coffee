app = require 'app'
BrowserWindow = require 'browser-window'
DeviceManager = require 'gateblu-forever'
Gateblu = require 'gateblu'
meshbluJSON = require './meshblu.json'
_ = require 'lodash'
ipc = require 'ipc'

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
  'unconfigured'
  'disconnected'
]

deviceManagerEvents = [
  'npm:stdout'
  'npm:stderr'
]

app.on 'window-all-closed', ->
  if process.platform != 'darwin'
    app.quit()

app.on 'ready', ->
  mainWindow = new BrowserWindow(width: 800, height: 600)
  deviceManager = new DeviceManager(meshbluJSON)
  gateblu = new Gateblu meshbluJSON, deviceManager

  _.each gatebluEvents, (event) =>
    gateblu.on event, (data) =>
      event = "gateblu:#{event}" unless event.indexOf('gateblu:') == 0
      mainWindow.webContents.send event, data

  _.each deviceManagerEvents, (event) =>
    deviceManager.on event, (data) =>
      mainWindow.webContents.send "gateblu:#{event}", data

  ipc.on 'asynchronous-message', (event, message) =>
    return unless message.topic?
    args = message.args
    args.push (error, message) =>
      event.sender.send 'asynchronous-response', {error: error, message: message}

    gateblu[message.topic].apply gateblu, args

  mainWindow.loadUrl 'file://' + __dirname + '/index.html'
  mainWindow.openDevTools()

  mainWindow.on 'closed', ->
    mainWindow = null
