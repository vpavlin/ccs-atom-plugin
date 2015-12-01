$ = jQuery = require 'jquery'
fs = require 'fs'
#require 'jquery-ui'
io = require 'socket.io-client'
{File} = require 'atom'


module.exports =
class RhCcsAtomRightPanel
  constructor: (serializedState) ->
    # Create root element
    @element = $('<div>', {id: 'rh-ccs-atom-right-panel'})
    @element.append('<h1>Dependencies</h1>')

    #Create an iframe
    #iframe = document.createElement('iframe')
    #iframe.id = 'rh-ccs-right-iframe'
    #iframe.src = 'http://localhost:3000/'
    #@element.appendChild(iframe)

    # Create a table
    table = $('<table>', {'rh-ccs-dep-table'})
    @element.append(table)

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element

  updateDepTable: (deps)->
    $('#rh-ccs-dep-table').load ->
      console.log(deps)
      content = $('<tbody>')
      for dep in deps['dependencies']
        do (dep) ->
          content.append('<tr><td>'+ dep + '</td></tr>')
      $('#rh-ccs-dep-table').append(content)

  updateDependencies: ->
    projectPath = atom.project.getPaths()[0]
    console.log projectPath
    isPackageJson = atom.project.contains(projectPath + '/package.json')
    if isPackageJson
      packageJson = new File(projectPath + '/package.json', false)
      packageJson.read().then( (packageJsonFile) =>
        parsedFile = JSON.parse(packageJsonFile)
        @updateDepTable(parsedFile))
#  initSocketio: ->
#    $(document).ready ->
#      socket = io.connect('http://localhost:3000')
#      socket.on 'atomRequestFileTree', ->
#        projectPath = atom.project.getPaths()[0]
#        console.log projectPath
#        isPackageJson = atom.project.contains(projectPath + '/package.json')
#        if isPackageJson
#          packageJson = new File(projectPath + '/package.json', false)
#          packageJson.read().then( (packageJsonFile) ->
#            parsedFile = JSON.parse(packageJsonFile)
#            socket.emit('serverSendFileTree',parsedFile['dependencies']))
#      socket.on 'connect', ->
#        socket.emit 'counterAtom', 1
#      socket.on 'counterServer', (counter) ->
#        callback = ->
#          socket.emit 'counterAtom', counter+1
#        setTimeout callback, 1000
