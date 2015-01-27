'use strict';

var fs   = require('fs-extra');
var path = require('path');

var HOME_DIR     = process.env.HOME || process.env.HOMEPATH || process.env.USERPROFILE;
var CONFIG_PATH  = path.join(HOME_DIR, '.config/gateblu');
var DEFAULT_FILE = path.join(CONFIG_PATH, 'meshblu.json');

module.exports = {
  loadConfig : function( configPath ) {
    configPath = configPath || DEFAULT_FILE;
    if(!fs.existsSync(configPath)){
      return null;
    }
    return JSON.parse(fs.readFileSync(configPath));
  },
  saveConfig : function(config, configPath) {
    config = config || {};

    config.path       = config.path         || CONFIG_PATH;
    config.devicePath = config.devicePath   || path.join(config.path, 'devices');
    config.tmpPath    = config.tmpPath      || path.join(config.path, 'tmp');
    config.crashPath  = config.crashPath    || path.join(config.path, 'crash');
    config.server     = config.server       || process.env.MESHBLU_SERVER || 'meshblu.octoblu.com';
    config.port       = config.port         || process.env.MESHBLU_PORT   || '80';


    configPath = configPath || DEFAULT_FILE;
    fs.mkdirpSync(config.path);
    return fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
  }
};
