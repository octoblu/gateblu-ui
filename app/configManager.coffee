'use strict'
fs = require('fs-extra')
path = require('path')
HOME_DIR = process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE
CONFIG_PATH = path.join HOME_DIR, '.config', 'gateblu'
DEFAULT_FILE = path.join CONFIG_PATH, 'meshblu.json'
module.exports =
  loadConfig: (configPath) ->
    configPath = configPath or DEFAULT_FILE
    if !fs.existsSync(configPath)
      return null

    JSON.parse fs.readFileSync(configPath)
  saveConfig: (config, configPath) ->
    config = config or {}
    config.path = config.path or CONFIG_PATH
    config.devicePath = config.devicePath or path.join(config.path, 'devices')
    config.tmpPath = config.tmpPath or path.join(config.path, 'tmp')
    config.crashPath = config.crashPath or path.join(config.path, 'crash')
    config.server = config.server or process.env.MESHBLU_SERVER or 'meshblu.octoblu.com'
    config.port = config.port or process.env.MESHBLU_PORT or '80'
    configPath = configPath or DEFAULT_FILE

    fs.mkdirpSync config.path
    fs.mkdirpSync config.devicePath
    fs.mkdirpSync config.tmpPath
    fs.mkdirpSync config.crashPath

    fs.writeFileSync configPath, JSON.stringify(config, null, 2)
