var skynet = require('skynet');

var configManager = require('./src/config-manager');
var config = configManager.loadConfig();

var skynetConnection = skynet.createConnection({ uuid: config.uuid, token: config.token });

skynetConnection.on('notReady', function(){
  if (!config.uuid) {
    skynetConnection.register({type: 'gateway'}, function(data){
      skynetConnection.identify({uuid: data.uuid, token: data.token});
    });
  }
});

var messageManager = require('./src/message-manager')(config, skynetConnection);

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

device = {name: 'test-subdevice', connector: 'meshblu-blink1', uuid: '1', token: '2'}
messageManager.setupDevice(device, messageManager.startDevice);
