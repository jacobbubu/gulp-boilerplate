appCacheChecker = require('./appCacheChecker')()

module.exports =
    isDebug: process.env.NODE_ENV is 'development'
    startUpdater: (opts) ->
        appCacheChecker.start opts

    clearConsole: -> console.clear()