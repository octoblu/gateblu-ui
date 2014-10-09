var fs = require('fs-extra');
var rimraf = require('rimraf');
var $ = require('./lib/jquery');
var configManager = require('./src/config-manager');
var config = configManager.loadConfig();

if (!config) {
  configManager.saveConfig();
  config = configManager.loadConfig();
}

rimraf.sync(config.path + '/dist');
fs.copySync('dist', config.path + '/dist');

var Genblu = require('genblu');
genblu = new Genblu(config);

genblu.on('config', function(config){
  $('ul.log').append('<li>Connected to Meshblu. UUID: '+config.uuid+'</li>');
  configManager.saveConfig(config);
});

genblu.on('device:start', function(device){
  $('ul.devices').append('<li>' + device.name + '(' + device.uuid + ')</li>' );
})
