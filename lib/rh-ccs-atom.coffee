RhCcsAtomRightPanel = require './rh-ccs-atom-right-panel'
RhCcsAtomModalPanel = require './rh-ccs-atom-modal-panel'
FileWatcher = require './fw'
$ = jQuery = require 'jquery'
{CompositeDisposable} = require 'atom'

module.exports = RhCcsAtom =
  rhCcsAtomModalPanel: null
  modalPanel: null
  rhCcsAtomRightPanel: null
  rightPanel: null
  subscriptions: null
  watcher: null

  activate: (state) ->
    @rhCcsAtomRightPanel = new RhCcsAtomRightPanel(state.rhCcsAtomRightPanelState)
    @rightPanel = atom.workspace.addRightPanel(item: @rhCcsAtomRightPanel.getElement(), visible: false)
    #@rhCcsAtomRightPanel.initSocketio()
    @rhCcsAtomModalPanel = new RhCcsAtomModalPanel(state.rhCcsAtomModalPanelState)
    @modalPanel = atom.workspace.addModalPanel(item: @rhCcsAtomModalPanel.getElement(), visible: false)
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable
    # Register command that toggles this view toggle handlerh
    @subscriptions.add atom.commands.add 'atom-workspace', 'rh-ccs-atom:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'rh-ccs-atom-modal:hide': => @modalPanel.hide()
    @rhCcsAtomRightPanel.setModalHandler(@rhCcsAtomModalPanel, @modalPanel)
    @rhCcsAtomRightPanel.updateDependencies()
    @rhCcsAtomRightPanel.updateStatusBar()
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      @watcher = FileWatcher(editor)

  consumeStatusBar: (statusBar) ->
    self = this
    @statusBarTile = statusBar.addLeftTile(item: $("<a href='#'><span id='rh-ccs-status-bar' style='float:right' data-color='orange'>Loading ...</span></a>"), priority: 100)
    $("#rh-ccs-status-bar").click(() ->
      self.rightPanel.show()
      )


  deactivate: ->
    @statusBarTile?.destroy()
    @statusBarTile = null
    @rightPanel.destroy()
    @subscriptions.dispose()
    @rhCcsAtomRightPanel.destroy()

  serialize: ->
    rhCcsAtomRightPanelState: @rhCcsAtomRightPanel.serialize()
    rhCcsAtomModalPanelState: @rhCcsAtomModalPanel.serialize()

  status: ->
    console.log "status called"


  toggle: ->
    console.log 'RhCcsAtom was toggled!'

    @rhCcsAtomRightPanel.updateDependencies()
    @rhCcsAtomRightPanel.updateStatusBar()
    if @rightPanel.isVisible()
      @rightPanel.hide()
      #@modalPanel.hide()
    else
      @rightPanel.show()
      #@modalPanel.show()
