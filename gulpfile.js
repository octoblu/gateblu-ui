'use strict';
var gulp           = require('gulp');
var coffee         = require('gulp-coffee');
var concat         = require('gulp-concat');
var bower          = require('gulp-bower');
var plumber        = require('gulp-plumber');
var mainBowerFiles = require('main-bower-files');

gulp.task('bower', function() {
  return bower()
    .pipe(gulp.dest('bower_components/'))
});

gulp.task('bower:concat', ['bower'], function(){
  return gulp.src(mainBowerFiles({filter: /\.js/}))
    .pipe(plumber())
      .pipe(concat('dependencies.js'))
    .pipe(gulp.dest('dist/'));
});

gulp.task('coffee', function(){
  gulp.src('./src/**/*.coffee')
    .pipe(coffee())
    .pipe((concat('application.js')))
    .pipe(gulp.dest('./dist'));
});

gulp.task('default', ['bower:concat', 'coffee']);

gulp.task('watch', ['default'], function() {
  gulp.watch(['./src/**/*.coffee'], ['coffee']);
});
