gulp = require('gulp')
coffee = require('gulp-coffee')
concat = require('gulp-concat')

gulp.task 'coffee', ->
  gulp.src('./src/**/*.coffee').pipe(coffee()).pipe(concat('application.js')).pipe gulp.dest('./dist')

gulp.task 'default', [ 'coffee' ]
gulp.task 'watch', [ 'default' ], ->
  gulp.watch [ './src/**/*.coffee' ], [ 'coffee' ]
