(function(){
'use strict';

var fs      = require('fs-extra');
var rimraf  = require('rimraf');
var request = require('request');

var $             = require('jquery');
var version       = require('./package.json').version;
var configManager = require('./src/config-manager');
var config        = configManager.loadConfig();

if (!config) {
  configManager.saveConfig();
  config = configManager.loadConfig();
}

rimraf.sync(config.path + '/dist');
fs.copySync('dist', config.path + '/dist');

var Gateblu = require('gateblu');
var gateblu = new Gateblu(config);

gateblu.on('config', function(config){
  $('ul.log').append('<li>Connected to Meshblu. UUID: '+config.uuid+'</li>');
  $('ul.log').append('<li>Goto <a href="https://app.octoblu.com/connect/nodes/" class="external-link">Octoblu</a> to configure the Gateblu</li>');
  configManager.saveConfig(config);
});

gateblu.on('device:start', function(device){
  $('ul.devices').append('<li>' + device.type + '(' + device.uuid + ')</li>' );
});

gateblu.on('refresh', function(){
  $('ul.devices').html('');
});

request.get('http://gateblu.octoblu.com/version.json', {json: true}, function(error, response, body){
  if(error){
    return;
  }

  if(body.version !== version){
    $('.update-container').removeClass('hidden');
  }
});

})();
