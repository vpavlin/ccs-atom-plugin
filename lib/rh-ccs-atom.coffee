RhCcsAtomRightPanel = require './rh-ccs-atom-right-panel'
RhCcsAtomModalPanel = require './rh-ccs-atom-modal-panel'
{CompositeDisposable} = require 'atom'

module.exports = RhCcsAtom =
  rhCcsAtomModalPanel: null
  modalPanel: null
  rhCcsAtomRightPanel: null
  rightPanel: null
  subscriptions: null

  activate: (state) ->
    @rhCcsAtomRightPanel = new RhCcsAtomRightPanel(state.rhCcsAtomRightPanelState)
    @rightPanel = atom.workspace.addRightPanel(item: @rhCcsAtomRightPanel.getElement(), visible: false)
    #@rhCcsAtomRightPanel.initSocketio()
    @rhCcsAtomModalPanel = new RhCcsAtomModalPanel(state.rhCcsAtomModalPanelState)
    @modalPanel = atom.workspace.addModalPanel(item: @rhCcsAtomModalPanel.getElement(), visible: false)
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'rh-ccs-atom:toggle': => @toggle()

  deactivate: ->
    @rightPanel.destroy()
    @subscriptions.dispose()
    @rhCcsAtomRightPanel.destroy()

  serialize: ->
    rhCcsAtomRightPanelState: @rhCcsAtomRightPanel.serialize()
    rhCcsAtomModalPanelState: @rhCcsAtomModalPanel.serialize()

  toggle: ->
    console.log 'RhCcsAtom was toggled!'

    if @rightPanel.isVisible()
      @rightPanel.hide()
      #@modalPanel.hide()
    else
      @rightPanel.show()
      @rhCcsAtomRightPanel.updateDependencies()
      #@modalPanel.show()
