(function(){
  'use strict';

  var $ = require('jquery');

  $(function(){
    var gui, openInBrowser;
    gui = require('nw.gui');

    openInBrowser = function(event) {
      event.preventDefault();
      event.stopPropagation();
      gui.Shell.openExternal($(event.currentTarget).prop('href'));
    };

    $('body').on('click', 'a.external-link', openInBrowser);
  });
})();
