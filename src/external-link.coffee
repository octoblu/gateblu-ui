(->
  $ = require("jquery")
  $ ->
    gui = undefined
    openInBrowser = undefined
    gui = require("nw.gui")
    openInBrowser = (event) ->
      event.preventDefault()
      event.stopPropagation()
      gui.Shell.openExternal $(event.currentTarget).prop("href")
      return

    $("body").on "click", "a.external-link", openInBrowser
    return

  return
)()
