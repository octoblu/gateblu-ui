var Gatenu = require('gatenu-npm');
var configManager = require('./src/config-manager');
var config = configManager.loadConfig();

if (!config.nodePath) {
  var node_path, platform_path;

  if (process.platform === 'win32') {
    platform_path = 'node-v0.10.32-win-x86';
  } else if (process.platform === 'darwin') {
    platform_path = 'node-v0.10.32-darwin-x64';
  } else {
    platform_path = 'node-v0.10.32-linux-x64';
  }

  config.nodePath = path.join(config.path, 'dist', platform_path, 'bin');
}

var gatenu = new Gatenu(config);
