$(function(){
'use strict';

var fs      = require('fs-extra');
var rimraf  = require('rimraf');
var request = require('request');
var _       = require('lodash');

var $             = require('jquery');
var version       = require('./package.json').version;
var configManager = require('./src/config-manager');
var config        = configManager.loadConfig();

process.on('uncaughtException', function(error){
  console.error(error.message);
  console.error(error.stack);
  $('ul.logs').append('<li>' + error.message + '</li>');
});

if (!config) {
  configManager.saveConfig();
  config = configManager.loadConfig();
}

rimraf.sync(config.path + '/dist');
fs.copySync('dist', config.path + '/dist');

var Gateblu = require('gateblu');
var gateblu = new Gateblu(config);

gateblu.on('config', function(config){
  $('ul.statuses').append('<li>Connected to Meshblu. UUID: '+config.uuid+'</li>');
  $('ul.statuses').append('<li>Goto <a href="https://app.octoblu.com/connect/nodes/" class="external-link">Octoblu</a> to configure the Gateblu</li>');
  configManager.saveConfig(config);
});

gateblu.on('update', function(devices){
  _.each(devices, function(device){
    var html = '<li data-uuid="'+device.uuid+'">' + device.type + '(' + device.uuid + ')</li>';
    $('ul.devices').append(html);
  })
});

gateblu.on('device:start', function(device){
  $('ul.devices li[data-uuid=' + device.uuid + ']').addClass('active');
});

gateblu.on('refresh', function(){
  $('ul.devices').html('');
  $('.logs').append('Refreshing Device List' + '\n');
});

gateblu.on('stderr', function(data, device){
  $('.logs').append("Error: " + device.name + '\n');
  $('.logs').append(data);
});

gateblu.on('stdout', function(data, device){
  $('.logs').append((device.name || device.uuid) + '\n');
  $('.logs').append(data);
});

request.get('http://gateblu.octoblu.com/version.json', {json: true}, function(error, response, body){
  if(error){
    $('.logs').append(error.message + '\n');
    return;
  }

  if(body.version !== version){
    $('.update-container').removeClass('hidden');
  }
});

});
