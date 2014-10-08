var $ = require('../lib/jquery');
var fs = require('fs-extra');
var path = require('path');
var rimraf = require('rimraf');
var exec = require('child_process').exec;

var node_path, platform_path;

if (process.platform === 'win32') {
  platform_path = 'node-v0.10.32-win-x86';
} else if (process.platform === 'darwin') {
  platform_path = 'node-v0.10.32-darwin-x64';
} else {
  platform_path = 'node-v0.10.32-linux-x64';
}

module.exports = function(config) {
  node_path = path.join(config.path, 'dist', platform_path, 'bin');
  var messageManager = {
    setupDevice : function(device, callback) {
      setupDevice(config, device, callback);
    },
    startDevice : function(device) {
      startDevice(config, device);
    }
  };

  return messageManager;
};

function setupDevice(config, device, callback) {
  var devicePath = path.join(config.devicePath, device.uuid);
  var devicePathTmp =  path.join(config.tmpPath, device.uuid);

  if(fs.existsSync(devicePath)) {
    rimraf.sync(devicePath);
  }

  if(fs.existsSync(devicePathTmp)) {
    rimraf.sync(devicePathTmp);
  }

  fs.mkdirpSync(devicePath);
  fs.mkdirpSync(devicePathTmp);

  try {
    exec('"' + path.join(node_path, 'npm') + '" --prefix=. install ' + device.connector, {cwd: devicePathTmp}, function(error, stdout, stderr) {
      if (error) {
        console.error(error);
        $('ul').append('<li><pre>' + error + '</pre></li>');
      }
      console.log(stdout);
      $('ul').append('<li><pre>' + stdout + '</pre></li>');
      $('ul').append('<li>' + path.join(devicePathTmp, 'node_modules', device.connector) + ':' + devicePath + '</li>');
      fs.copySync(path.join(devicePathTmp, 'node_modules', device.connector), devicePath);
      fs.writeFileSync(path.join(devicePath, 'meshblu.json'), JSON.stringify(device));
      rimraf.sync(devicePathTmp);
      if (callback) {
        callback(device);
      }
    });
  } catch (error) {
    $('ul').append('<li><pre>' + error + '</pre></li>');
  }
}

function startDevice(config, device) {
  var devicePath = path.join(config.devicePath, device.uuid);
  exec('"' + path.join(node_path, 'npm') + '" start', {cwd: devicePath});
}
