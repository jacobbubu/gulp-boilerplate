browserify   = require 'browserify'
browserSync  = require 'browser-sync'
chalk        = require 'chalk'
CSSmin       = require 'gulp-minify-css'
filter       = require 'gulp-filter'
gulp         = require 'gulp'
gutil        = require 'gulp-util'
jade         = require 'gulp-jade'
path         = require 'path'
prefix       = require 'gulp-autoprefixer'
prettyTime   = require 'pretty-hrtime'
source       = require 'vinyl-source-stream'
sourcemaps   = require 'gulp-sourcemaps'
stylus       = require 'gulp-stylus'
uglify       = require 'gulp-uglify'
watchify     = require 'watchify'
buffer       = require 'vinyl-buffer'
size         = require 'gulp-size'
manifest     = require 'gulp-manifest'
notify       = require 'gulp-notify'
runSequence  = require 'run-sequence'

process.env.NODE_ENV ?= 'development'
production   = process.env.NODE_ENV is 'production'

config =
    scripts:
        source: './src/coffee/main.coffee'
        extensions: ['.coffee']
        transforms: ['coffee-reactify', 'envify']
        destination: './dist/js/'
        filename: 'bundle.js'
    templates:
        source: './src/jade/*.jade'
        watch: './src/jade/*.jade'
        destination: './dist/'
    styles:
        source: './src/stylus/style.styl'
        watch: './src/stylus/*.styl'
        destination: './dist/css/'
    assets:
        source: './src/assets/**/*.*'
        watch: './src/assets/**/*.*'
        destination: './dist/'
    manifest:
        source: './dist/**/*.*'
        destination: './dist/'
        filename: 'app.appcache'

handleError = (err) ->
    gutil.log err
    gutil.beep()
    @emit 'end'

gulp.task 'scripts', ->

    bundle = browserify
        entries: [config.scripts.source]
        extensions: config.scripts.extensions
        debug: not production

    config.scripts.transforms.forEach (t) -> bundle.transform t

    build = bundle.bundle()
        .on 'error', handleError
        # convert node stream to vinyl stream
        .pipe source config.scripts.filename
        # vinyl stream to buffer for size plug-in using
        # and also this is a more perfomant way
        .pipe buffer()
        .pipe sourcemaps.init loadMaps: true

    if production
        build = build.pipe uglify()
        build.pipe size showFiles: true, gzip: true

    build
        .pipe sourcemaps.write '.'
        .pipe gulp.dest config.scripts.destination

gulp.task 'templates', ->
    pipeline = gulp
        .src config.templates.source
        .pipe jade
            pretty: not production

        .on 'error', handleError
        .pipe gulp.dest config.templates.destination

    pipeline = pipeline.pipe browserSync.reload(stream: true) unless production

    pipeline

gulp.task 'styles', ->
    styles = gulp.src config.styles.source
    styles = styles.pipe sourcemaps.init() unless production
    styles = styles.pipe stylus
            'include css': true

        .on 'error', handleError
        .pipe prefix 'last 2 versions', 'Chrome 34', 'Firefox 28', 'iOS 7'

    styles = styles.pipe CSSmin() if production
    styles = styles.pipe sourcemaps.write '.' unless production
    styles = styles.pipe gulp.dest config.styles.destination

    unless production
        styles = styles
            .pipe filter '**/*.css'
            .pipe browserSync.reload stream: true

    styles

gulp.task 'assets', ->
    gulp
        .src config.assets.source
        .pipe gulp.dest config.assets.destination

gulp.task 'server', ->
    browserSync
        port:      9001
        server:
            baseDir: './dist'

gulp.task 'manifest', ->
    gulp.src config.manifest.source
        .pipe manifest
            timestamp: not production
            hash: true
            preferOnline: true
            network: ['http://*', 'https://*', '*']
            filename: config.manifest.filename
            exclude: config.manifest.filename

        .pipe gulp.dest config.manifest.destination

gulp.task 'watch', ->
    gulp.watch config.templates.watch, -> runSequence 'templates', 'manifest'
    gulp.watch config.styles.watch, -> runSequence 'styles', 'manifest'
    gulp.watch config.assets.watch, -> runSequence 'assets', 'manifest'

    bundle = watchify browserify
        entries: [config.scripts.source]
        extensions: config.scripts.extensions
        debug: not production
        cache: {}
        packageCache: {}
        fullPaths: true

    config.scripts.transforms.forEach (t) -> bundle.transform t

    bundle.on 'update', ->
        gutil.log "Starting '#{chalk.cyan 'rebundle'}'..."
        start = process.hrtime()
        build = bundle.bundle()
            .on 'error', handleError
            .pipe source config.scripts.filename
            .pipe buffer()
            .pipe sourcemaps.init loadMaps: true

        build
            .pipe sourcemaps.write '.'
            .pipe gulp.dest config.scripts.destination
            .pipe notify
                onLast: true
                message: "Finished rebundle after #{prettyTime process.hrtime start}"
            .on 'finish', ->
                gulp.start 'manifest'
                gutil.log "Finished '#{chalk.cyan 'rebundle'}' after #{chalk.magenta prettyTime process.hrtime start}"
            .pipe browserSync.reload stream: true

    .emit 'update'

gulp.task 'no-js', ['templates', 'styles', 'assets']
gulp.task 'build', ['scripts', 'no-js'], ->
    gulp.start 'manifest'

# scripts and watch conflict and will produce invalid js upon first run
# which is why the no-js task exists.
gulp.task 'default', ['watch', 'no-js', 'server']