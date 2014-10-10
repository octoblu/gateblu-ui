(function(){
'use strict';

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
var genblu = new Genblu(config);

genblu.on('config', function(config){
  $('ul.log').append('<li>Connected to Meshblu. UUID: '+config.uuid+'</li>');
  $('ul.log').append('<li>Goto <a href="https://octoblu.octoblu.com/connect/nodes/">Octoblu</a> to configure the Genblu</li>');
  configManager.saveConfig(config);
});

genblu.on('device:start', function(device){
  $('ul.devices').append('<li>' + device.name + '(' + device.uuid + ')</li>' );
});

genblu.on('refresh', function(){
  $('ul.devices').html('');
});

})();
