gulp = require('gulp')
coffee = require('gulp-coffee')
concat = require('gulp-concat')

gulp.task 'coffee', ->
  gulp.src(['./src/app.coffee','./src/**/*.coffee']).pipe(coffee(bare: true)).pipe(concat('application.js')).pipe gulp.dest('./app/dist')

gulp.task 'copy-package', ->
  gulp.src('package.json').pipe(gulp.dest('app'))
  gulp.src([
    'node_modules/lodash/dist/lodash.min.js'
    'node_modules/jquery/dist/jquery.min.js'
    'node_modules/angular/angular.min.js'
    'node_modules/angular-animate/angular-animate.min.js'
    'node_modules/angular-aria/angular-aria.min.js'
    'node_modules/angular-material/angular-material.min.js'
    ]).pipe(gulp.dest('app/dist/js'))
  gulp.src([
    'node_modules/angular-material/angular-material.min.css'
    'node_modules/font-awesome/css/font-awesome.min.css'
  ]).pipe(gulp.dest('app/dist/css'))
  gulp.src([
    'node_modules/font-awesome/fonts/*'
  ]).pipe(gulp.dest('app/dist/fonts'))

gulp.task 'default', [ 'coffee', 'copy-package' ]
gulp.task 'watch', [ 'default' ], ->
  gulp.watch [ './src/**/*.coffee' ], [ 'coffee' ]
  gulp.watch [ 'package.json' ], [ 'copy-package' ]
