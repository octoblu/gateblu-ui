var gulp         = require('gulp');
var coffee = require('gulp-coffee');
var concat = require('gulp-concat');

gulp.task('coffee', function(){
  gulp.src('./src/**/*.coffee')
    .pipe(coffee())
    .pipe((concat('application.js')))
    .pipe(gulp.dest('./dist'));
});

gulp.task('default', ['coffee']);

gulp.task('watch', ['default'], function() {
  gulp.watch(['./src/**/*.coffee'], ['coffee']);
});
