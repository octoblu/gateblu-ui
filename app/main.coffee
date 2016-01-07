app = require 'app'
BrowserWindow = require 'browser-window'
_ = require 'lodash'
ipc = require 'ipc'
shell = require 'shell'
debug = require('debug')('gateblu-ui')

mainWindow = null

app.on 'window-all-closed', ->
  if process.platform != 'darwin'
    app.quit()

app.on 'ready', ->
  mainWindow = new BrowserWindow width: 800, height: 600

  ipc.on 'asynchronous-message', (event, message) ->
    debug 'event', event
    debug 'message', message
    return unless message.topic == 'refresh'
    initializeGateway()

  mainWindow.loadUrl 'file://' + __dirname + '/index.html'

  mainWindow.on 'closed', ->
    mainWindow = null

  ipc.on 'asynchronous-message', (event, message) =>
    return unless message.topic?
    return shell.openExternal(message.link) if message.topic == 'external-link'
    return mainWindow.toggleDevTools() if message.topic == 'dev-tools'

app.on 'window-all-closed', ->
  app.quit()
