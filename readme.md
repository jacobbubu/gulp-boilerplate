# Gulp Boilerplate

Thos repo. is heavyly inspired by https://github.com/leonidas/gulp-project-template/blob/master/gulpfile.coffee.

This is a boilerplate used by myself to combine gulp, browserify, coffee-script, react.js, jade, styles and so on.

Please run

```npm install```

before try it.

Using

```npm run prod```

to build a production version. That includes uglified js and minified stylesheet.

Run

```npm start```

for development. A web server running by [browsersync](http://www.browsersync.io) will be started and listening on port `9001`. [browsersync](http://www.browsersync.io) will watch on the file changes and then rebuild them.

An "app.appcache" manifest will be emmited as the default configuration, and also the sourcemaps of coffee-script, stylus will be outouted too.

A lot of details in `gulpfile.coffee`, please read it carefully. :)