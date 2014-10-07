var fs = require('fs');
var DEFAULT_PATH = 'meshblu.json';

module.exports = {
    loadConfig : function( configPath ) {
        configPath = configPath || DEFAULT_PATH;
        if( !fs.existsSync(configPath) ) {
            return {};
        }
        return JSON.parse(fs.readFileSync(configPath))
    },
    saveConfig : function(config, configPath) {
        configPath = configPath || DEFAULT_PATH;
        return fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
    }
};