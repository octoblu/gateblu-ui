var skynet = require('skynet');

var configManager = require('./src/config-manager');
var config = configManager.loadConfig();

$('ul').append('<li>create connection</li>');
var skynetConnection = skynet.createConnection({ uuid: config.uuid, token: config.token });

skynetConnection.on('notReady', function(){
  if (!config.uuid) {
    $('ul').append('<li>Registering with skynet</li>');
    skynetConnection.register({type: 'gateway'}, function(data){
      $('ul').append('<li>Registered</li>');
      $('ul').append('<li>Identifying</li>');
      skynetConnection.identify({uuid: data.uuid, token: data.token});
    });
  }
});

var messageManager = require('./src/message-manager')(config, skynetConnection);

skynetConnection.on('ready', function(readyResponse){
  try {

    $('ul').append('<li>Ready</li>');
    config.uuid = readyResponse.uuid;
    config.token = readyResponse.token;
    configManager.saveConfig(config);

    device = {name: 'test-subdevice', connector: 'meshblu-echo', uuid: 'f105d101-4ea8-11e4-9133-338b9914afd1', token: '000xfoik6yptoi529egexh80t3rcc8fr'}
    messageManager.setupDevice(device, messageManager.startDevice);
  } catch (error) {
    console.log(error);
    $('ul').append('<li>' + error.stack + '</li>');
  }
});

skynetConnection.on('message', function(message){
 if( messageManager[message.topic] ) {
   messageManager[message.topic](message.payload);
 }
});

