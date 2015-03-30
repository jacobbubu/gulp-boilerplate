debug = require './debug'
if debug.isDebug
    debug.clearConsole()
    debug.startUpdater autoReload: true, checkInterval: 3000

React = require 'react'

React.render <h1>No coffee, no code.</h1>, document.getElementById 'container'