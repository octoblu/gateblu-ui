gui = require("nw.gui")
click_quit = ->
  gui.App.quit()
  return

# Create a tray icon
tray = new gui.Tray(
  title: ""
  icon: "img/icon.png"
)
tray.tooltip = "Octoblu Gateway"
menu = new gui.Menu()
menu.append new gui.MenuItem(
  type: "normal"
  label: "Quit"
  click: click_quit
)
tray.menu = menu
