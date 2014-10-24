if process.platform == 'darwin'
  gui = require 'nw.gui'
  mb = new gui.Menu {type:"menubar"}
  mb.createMacBuiltin "Gateblu"
  gui.Window.get().menu = mb
