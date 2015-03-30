DEFAULT_CHECK_INTERVAL = 30000

class Events
    constructor: ->
        @events = {}

        #listen to events
    on: (type, func, ctx) ->
        @events[type] ?= []
        @events[type].push { f: func, c: ctx }

        # stop listening to event / specific callback
    off: (type, func) ->
        list = @events[type] ? []
        i = if func then list.length else 0
        while i > 0
            i--
            list.splice(i,1) if func is list[i].f

    #  send event, callbacks will be triggered
    trigger: (args...) ->
        list = @events[args.shift()] ? []
        i = list.length
        for j in [0...i]
            list[j].f.apply list[j].c, args

isSafari = Object.prototype.toString.call(window.HTMLElement).indexOf('Constructor') > 0

module.exports = ->
    appCache = window.applicationCache
    throw new Error "This browser does not support window.applicationCache" unless appCache

    appCacheChecker = new Events()
    appCacheChecker.start = (opts) ->
        opts ?= {}
        opts.checkInterval ?= DEFAULT_CHECK_INTERVAL
        opts.autoReload ?= false

        appCacheChecker.options = opts
        subscribeToEvents()
        appCacheChecker.started = true
        recheck appCacheChecker.options.checkInterval
        appCacheChecker.trigger 'start'

    appCacheChecker.stop = ->
        return if not appCacheChecker.started
        if appCacheChecker.timer
            clearTimeout appCacheChecker.timer
            appCacheChecker.timer = null
        unsubscribeToEvents()
        appCacheChecker.started = false
        appCacheChecker.trigger 'stop'

    recheck = (interval) ->
        return if not appCacheChecker.started
        appCacheChecker.timer = setTimeout ->
            update()
            recheck interval
        , interval

    update = ->
        appCacheChecker.trigger 'update'
        try
            applicationCache.update()
            true
        catch e
            false

    bind = (eventName, cb) ->
        appCache.addEventListener eventName, cb, false

    unbind = (eventName, cb) ->
        appCache.removeEventListener eventName, cb, false

    subscribeToEvents = ->
        # Fired when the manifest resources have been downloaded.
        bind 'updateready', handleUpdateReady

        # fired when manifest download request failed
        # (no connection or 5xx server response)
        bind 'error',       handleNetworkError

        # fired when manifest download request succeeded
        # but server returned 404 / 410
        bind 'obsolete',    handleNetworkObsolete

        # fired when manifest download succeeded
        bind 'noupdate',    handleNetworkSucces
        bind 'cached',      handleNetworkSucces
        bind 'updateready', handleNetworkSucces
        bind 'progress',    handleNetworkSucces
        bind 'downloading', handleNetworkSucces

        # when browser goes online/offline, look for updates to make sure.
        addEventListener 'online', update, false
        addEventListener 'offline', update, false

    unsubscribeToEvents = ->
        unbind 'updateready', handleUpdateReady
        unbind 'error',       handleNetworkError
        unbind 'obsolete',    handleNetworkObsolete
        unbind 'noupdate',    handleNetworkSucces
        unbind 'cached',      handleNetworkSucces
        unbind 'updateready', handleNetworkSucces
        unbind 'progress',    handleNetworkSucces
        unbind 'downloading', handleNetworkSucces

        removeEventListener 'online', update, false
        removeEventListener 'offline', update, false

    handleUpdateReady = ->
        appCacheChecker.trigger 'updateready'
        if appCacheChecker.options.autoReload
            if not isSafari
                location.reload()

    handleNetworkError = ->
    handleNetworkSucces = ->
    handleNetworkObsolete = ->

    appCacheChecker



