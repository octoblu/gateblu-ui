
class Application
  run: =>
    {Tray} = requireNode 'nw.gui'
    tray = new Tray title: 'Tray', icon: 'img/icon.png'

new Application.run()
