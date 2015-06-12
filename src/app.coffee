angular.module 'gateblu-ui', ['ngMaterial']
.config ($mdThemingProvider) =>
  $mdThemingProvider.definePalette 'octo-blue',
    '50': '82bbed'
    '100': '5ea8e8'
    '200': '3b94e3'
    '300': '1f81d6'
    '400': '196bb3'
    '500': '14568f'
    '600': '124b7d'
    '700': '0f406b'
    '800': '0d3659'
    '900': '0a2b47'
    'A100': '6c9aff'
    'A200': '3374ff'
    'A400': '0a58ff'
    'A700': '0047e0'
    'contrastDefaultColor': 'light'

    'contrastDarkColors': ['50', '100', '200', '300', '400', 'A100'],
    'contrastLightColors': undefined

  $mdThemingProvider.theme 'default'
    .primaryPalette 'octo-blue'
    .accentPalette 'green', 'default': '500'

  $mdThemingProvider.theme 'logs'
    .primaryPalette 'green'
    .accentPalette 'blue', 'default': '500'

  $mdThemingProvider.theme 'info'
    .primaryPalette 'green'
    .accentPalette 'blue', 'default': '500'

  $mdThemingProvider.theme 'confirm'
    .primaryPalette 'red'
    .accentPalette 'purple', 'default': '500'

  $mdThemingProvider.theme 'warning'
    .primaryPalette 'yellow'
    .accentPalette 'green', 'default': '500'
