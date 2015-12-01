$ = jQuery = require 'jquery'
fs = require 'fs'
#require 'jquery-ui'
io = require 'socket.io-client'
{File} = require 'atom'


module.exports =
class RhCcsAtomModalPanel
  constructor: (serializedState) ->
    # Create root element
    @element = document.createElement('div')
    @element.id = 'rh-ccs-atom'

    #Create an iframe
    iframe = document.createElement('iframe')
    iframe.id = 'rh-ccs-modal-iframe'
    iframe.src = 'http://localhost:3000/'
    @element.appendChild(iframe)

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element
