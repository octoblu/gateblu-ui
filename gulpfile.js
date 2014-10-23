var gulp         = require('gulp');
var coffee = require('gulp-coffee');
var concat = require('gulp-concat');
var sourcemaps = require('gulp-sourcemaps');

gulp.task('coffee', function(){
  gulp.src('./src/**/*.coffee')
    .pipe(sourcemaps.init())
    .pipe(coffee())
    .pipe((concat('dist.js')))
    .pipe(sourcemaps.write())
    .pipe(gulp.dest('./src'))
});

gulp.task('default', ['coffee']);

gulp.task('watch', ['default'], function() {
  gulp.watch(['./src/**/*.coffee'], ['coffee']);
});
