var npm = require('npm');
var fs = require('fs');
var path = require('path');
var rimraf = require('rimraf');
module.exports = function(config, skynetConnection) {
    var messageManager = {
        setupDevice : function(device) {
            //1. create path (if it doesn't exist)
            installDevice(config, device)
        }
    };

    return messageManager;
};

function installDevice(config, device) {
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

    npm.load({prefix: devicePathTmp, depth: 0, save: true}, function (error, npmInstance) {
        npmInstance.commands.install([device.connector], function (error, results) {
            fs.renameSync(path.join(devicePathTmp, 'node_modules', device.connector), devicePath);
            fs.writeFileSync(path.join(devicePath, 'meshblu.json'), JSON.stringify(device));
            rimraf.sync(devicePathTmp);
        });
    });
}