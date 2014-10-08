var npm = require('npm');
var fs = require('fs-extra');
var path = require('path');
var rimraf = require('rimraf');
var forever = require('forever-monitor');
var exec = require('child_process').exec;

var node_path, platform_path;

if (process.platform === 'win32') {
  platform_path = 'node-v0.10.32-win-x32';
} else if (process.platform === 'darwin') {
  platform_path = 'node-v0.10.32-darwin-x64';
} else {
  platform_path = 'node-v0.10.32-linux-x64';
}

node_path = path.join(__dirname, '../dist', platform_path, 'bin');

module.exports = function(config) {
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

  exec('echo $PWD && ' + path.join(node_path, 'npm') + ' --prefix=. install ' + device.connector, {cwd: devicePathTmp}, function(error, stdout, stderr) {
    if (error) {
      console.error(error);
    }
    console.log(stdout);
    fs.renameSync(path.join(devicePathTmp, 'node_modules', device.connector), devicePath);
    fs.writeFileSync(path.join(devicePath, 'meshblu.json'), JSON.stringify(device));
    rimraf.sync(devicePathTmp);
    if (callback) {
      callback(device);
    }
  });
}

function startDevice(config, device) {
  var devicePath = path.join(config.devicePath, device.uuid);
  var child = new (forever.Monitor)('start', {
    max: 3,
    silent: true,
    options: [],
    cwd: devicePath,
    logFile: devicePath + '/forever.log',
    outFile: devicePath + '/forever.stdout',
    errFile: devicePath + '/forever.stderr',
    command: path.join(node_path, 'npm')
  });

  child.on('exit', function () {
    console.log('The device exited after 3 restarts');
  });

  child.start();
}
