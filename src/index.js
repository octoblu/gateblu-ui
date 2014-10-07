var skynet = require('skynet');
var forever = require('forever');
var _ = require('lodash');

var configManager = require('./config-manager');
var config = configManager.loadConfig();

var skynetConnection = skynet.createConnection({ uuid: config.uuid, token: config.token });

var messageManager = require('./message-manager')(config, skynetConnection);

skynetConnection.on('ready', function(readyResponse){
    config.uuid = readyResponse.uuid;
    config.token = readyResponse.token;
    configManager.saveConfig(config);
});

skynetConnection.on('message', function(message){
   if( messageManager[message.topic] ) {
       messageManager[message.topic](message.payload);
   }
});

messageManager.setupDevice({name: 'test-subdevice', connector: 'skynet-wemo', uuid: '1'});