var fs = require('fs-extra');
var rimraf = require('rimraf');
var configManager = require('./src/config-manager');
var config = configManager.loadConfig();

if (!config) {
  configManager.saveConfig();
  config = configManager.loadConfig();
}

rimraf.sync(config.path + '/dist');
fs.copySync('dist', config.path + '/dist');

var Gatenu = require('gatenu-npm');
gatenu = new Gatenu(config);
gatenu.on('config', function(config){
  configManager.saveConfig(config);
})
