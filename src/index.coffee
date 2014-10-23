$ ->
  "use strict"
  fs = require("fs-extra")
  rimraf = require("rimraf")
  request = require("request")
  _ = require("lodash")
  $ = require("jquery")
  version = require("./package.json").version
  configManager = require("./src/config-manager")
  config = configManager.loadConfig()
  process.on "uncaughtException", (error) ->
    console.error error.message
    console.error error.stack
    $("ul.logs").append "<li>" + error.message + "</li>"
    return

  unless config
    configManager.saveConfig()
    config = configManager.loadConfig()
  rimraf.sync config.path + "/dist"
  fs.copySync "dist", config.path + "/dist"
  Gateblu = require("gateblu")
  gateblu = new Gateblu(config)
  gateblu.on "config", (config) ->
    $("ul.statuses").append "<li>Connected to Meshblu. UUID: " + config.uuid + "</li>"
    $("ul.statuses").append "<li>Goto <a href=\"https://app.octoblu.com/connect/nodes/\" class=\"external-link\">Octoblu</a> to configure the Gateblu</li>"
    configManager.saveConfig config
    return

  gateblu.on "update", (devices) ->
    _.each devices, (device) ->
      html = "<li data-uuid=\"" + device.uuid + "\">" + device.type + "(" + device.uuid + ")</li>"
      $("ul.devices").append html
      return

    return

  gateblu.on "device:start", (device) ->
    $("ul.devices li[data-uuid=" + device.uuid + "]").addClass "active"
    return

  gateblu.on "refresh", ->
    $("ul.devices").html ""
    $(".logs").append "Refreshing Device List" + "\n"
    return

  gateblu.on "stderr", (data, device) ->
    $(".logs").append "Error: " + device.name + "\n"
    $(".logs").append data
    return

  gateblu.on "stdout", (data, device) ->
    $(".logs").append (device.name or device.uuid) + "\n"
    $(".logs").append data
    return

  request.get "http://gateblu.octoblu.com/version.json",
    json: true
  , (error, response, body) ->
    if error
      $(".logs").append error.message + "\n"
      return
    $(".update-container").removeClass "hidden"  if body.version isnt version
    return

  return
