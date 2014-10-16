var gui     = require('nw.gui');

var click_quit = function() {
  gui.App.quit();
}

// Create a tray icon
var tray = new gui.Tray({ title: '', icon: 'img/icon.png' });
tray.tooltip = "Octoblu Gateway";

var menu = new gui.Menu();
menu.append(new gui.MenuItem({ type: 'normal', label: 'Quit', click: click_quit }));
tray.menu = menu;



