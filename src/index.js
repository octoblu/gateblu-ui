var configManager = require('./src/config-manager');
var config = configManager.loadConfig();

var gatenu = require('gatenu-npm')(config);
