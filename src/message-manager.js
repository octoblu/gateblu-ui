var npm = require('npm');
var fs = require('fs');
var path = require('path');
var rimraf = require('rimraf');
var forever = require('forever-monitor');
var exec = require('child_process').exec;

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
  var devicePath = path.join(config.devicePath || 'devices', device.uuid);
  var devicePathTmp =  path.join(config.tmpPath || 'tmp', device.uuid);

  if(fs.existsSync(devicePath)) {
    rimraf.sync(devicePath);
  }

  if(fs.existsSync(devicePathTmp)) {
    rimraf.sync(devicePathTmp);
  }

  fs.mkdirSync(devicePath);
  fs.mkdirSync(devicePathTmp);


  exec('../../dist/node-v0.10.32-darwin-x64/bin/npm --prefix=. install ' + device.connector, {cwd: devicePathTmp}, function(error, stdout, stderr) {
    if (error) {
      console.log(error);
    }
    console.log(stdout);
    console.error(stderr);
    fs.renameSync(path.join(devicePathTmp, 'node_modules', device.connector), devicePath);
    fs.writeFileSync(path.join(devicePath, 'meshblu.json'), JSON.stringify(device));
    rimraf.sync(devicePathTmp);
    if (callback) {
      callback(device);
    }
  });
}

function startDevice(config, device) {
  var devicePath = path.join(config.devicePath || 'devices', device.uuid);
  console.log('cd ' + devicePath + ' && NODE_PATH=' + devicePath + '/node_modules dist/node-v0.10.32-darwin-x64/bin/npm start');
  var child = new (forever.Monitor)('start', {
    max: 3,
    silent: true,
    options: [],
    cwd: devicePath,
    logFile: devicePath + '/forever.log',
    outFile: devicePath + '/forever.stdout',
    errFile: devicePath + '/forever.stderr',
    command: '../../dist/node-v0.10.32-darwin-x64/bin/npm'
  });

  child.on('exit', function () {
    console.log('The device exited after 3 restarts');
  });

  child.start();
}
