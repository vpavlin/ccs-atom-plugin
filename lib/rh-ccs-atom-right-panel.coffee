$ = jQuery = require 'jquery'
fs = require 'fs'
{File} = require 'atom'
Data = require './data'

module.exports =
class RhCcsAtomRightPanel
  timers = {}
  modal_obj = undefined
  modal_elem = undefined
  data = undefined
  file_watch_timer = undefined
  constructor: (serializedState) ->
    # Create root element
    @element = $('<div>', {id: 'rh-ccs-atom-right-panel'})
    $(@element).append('<h1>Dependencies</h1>')

    #Create an iframe
    #iframe = document.createElement('iframe')
    #iframe.id = 'rh-ccs-right-iframe'
    #iframe.src = 'http://localhost:3000/'
    #@element.appendChild(iframe)

    # Create a table
    table = $('<table>', {id: 'rh-ccs-dep-table'})
    table.append("<tr><th>Name</th><th>Version<th>Score</th><th></th></tr>")
    $(@element).append(table)

    data = new Data()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element

  updateDepTable: (changes)->
    #console.log(data.getDeps())
    content = $("#rh-ccs-dep-table tbody")
    if $(content).html() == undefined
      content = $('<tbody>')

    for dep in data.getDeps()
      if $("#rh-ccs-dep-table ##{dep.id}").html() == undefined
        content.append("<tr id='#{dep.id}'><td>#{dep.name}</td><td class='version'>#{dep.pkgver}</td><td class='score'>#{data.countScore(dep)}</td><td class='buttons'>Loading...</td></tr>")
        @checkCucos(dep)
      else
        @button = $("#rh-ccs-dep-table ##{dep.id} .analyze")
        if $(@button).html() != undefined
          console.log "Checking #{dep.name} again"
          @checkCucos(dep)
    if changes.added.length > 0
      $('#rh-ccs-dep-table').append(content)

    console.log changes
    for rem in changes.removed
      console.log $("#rh-ccs-dep-table ##{rem}").html()
      if $("#rh-ccs-dep-table ##{rem}").html() != undefined
        $("#rh-ccs-dep-table ##{rem}").remove()

    if changes.removed.length > 0
      @updateStatusBar()


  updateStatusBar: () ->
    #console.log "Updating Status Bar"
    @bar = $("#rh-ccs-status-bar")
    if $(@bar).html() == undefined or $(@bar).html() == "Loading..."
      setTimeout(@updateStatusBar, 500)
      return

    @analyzed = 0
    @to_analyze = 0
    @cves = 0
    @some_undefined = false
    for dep in data.getDeps()
      if data.getCVEsLen(dep) > 0
        @cves++
      if dep.analyzed == true
        @analyzed++
      else if dep.analyzed == false
        @to_analyze++
      else if dep.analyzed == undefined
        @some_undefined = true

    @text = ""
    @orig_color = $(@bar).attr('data-color')
    @color = @orig_color
    @text = "You are all good!"
    if !@some_undefined
      if @cves > 0
          @text = "CVEs found in #{@cves} deps"
          @color = "red"

      if @to_analyze == 0
        if @cves == 0
          @text = "You are all good!"
          @color = "green"
        @text +=" (All #{@analyzed} deps analyzed)"
      else if @analyzed == 0
        @text = "Ugh, this is terrible (All #{@to_analyze} deps not analyzed)"
        @color = "red"
      else
        @tmp_text = "#{@to_analyze} deps to analyze"
        if @cves == 0
          @text = @tmp_text
          @color = "orange"
        else
          @text += ", "+@tmp_text
        @text += " (#{@analyzed} deps analyzed)"


      $(@bar).html(@text).removeClass(@orig_color).attr('data-color', @color).addClass(@color)

  cucosResponse: (self, id, metadata) ->
    btn = "<a href='##{id}' class='detail'>Detail</a>"
    d = data.findInDeps(id)
    try
      d.metadata = JSON.parse(metadata.properties.metadata[0])
    catch err
      console.log
      btn = "Error"

    $("#rh-ccs-dep-table ##{id}").find("td").last().html(btn)
    if data.getCVEsLen(d) > 0
      $("#rh-ccs-dep-table ##{id}").find("td").first().addClass("red")

    $("#rh-ccs-dep-table ##{id} .detail").click(() ->
      modal_elem.show()
      modal_obj.showModal(id)
    )
    @updateStatusBar()
    if timers[id] != undefined
      clearInterval(timers[id])
      delete timers[id]

    @updateScore(d)

  updateScore: (dep) ->
    @score = data.countScore(dep)
    $("#rh-ccs-dep-table ##{dep.id} .score").html(@score).addClass(data.scoreToColor(@score))

  cucosAnalyzeRequest: (id) ->
    self = this
    dep = data.findInDeps(id)
    $("#rh-ccs-dep-table ##{id}").find("td").last().html("Analyzing...")
    console.log "Sending analyze request for #{dep.name}-#{dep.cucosver}"
    @host = "http://localhost:8000/api/analyze-package-version/"
    @data = {'ecosystem': 'nodejs', 'package': "#{dep.name}", 'version': "#{dep.cucosver}", 'artifact_url': 'http://not/important/right/now'}
    console.log @data
    $.post(@host, JSON.stringify(@data), (d) ->
      console.log "Request sent to cucos, response: #{JSON.stringify(d)}"
      timers[id] = setInterval(() ->
            self.checkCucos(dep)
          , 1000)
      ).fail(() ->
        console.log "Request failed:/"
        alert("Request for analysis failed:(")
        @cucosNotFound(id)
        )

  cucosNotFound: (self, id) ->
    if timers[id] != undefined
      return

    $("#rh-ccs-dep-table ##{id}").find("td").last().html("<a href='##{id}' class='analyze'>Analyze</a>")
    $("#rh-ccs-dep-table ##{id} .analyze").click(() ->
      self.cucosAnalyzeRequest(id)
    )
    @updateStatusBar()

  checkCucos: (pkg) ->
    self = this
    host = "https://scp.artifactoryonline.com/scp"
    ecosystem = "npm-mirror-cache"
    artifact = pkg.name
    folder = "-"
    item = "#{pkg.name}-#{pkg.cucosver}.tgz"
    uri = "#{host}/api/storage/#{ecosystem}/#{artifact}/#{folder}/#{item}?properties"
    id = data.nvrToId(pkg.name, pkg.cucosver)
    $.get(uri, (data) ->
      pkg.analyzed = true
      self.cucosResponse(self, id, data)
      ).fail( () ->
        pkg.analyzed = false
        self.cucosNotFound(self, id)
      )

  setFileWatchTimer: ->
    self = this
    if @file_watch_timer != undefined
      clearTimeout(@file_watch_timer)
      @file_watch_timer = undefined

    @file_watch_timer = setTimeout(() ->
        self.updateDependencies()
      , 30000)

  updateDependencies: ->
    projectPath = atom.project.getPaths()[0]
    #console.log projectPath
    isPackageJson = atom.project.contains(projectPath + '/package.json')
    if isPackageJson
      packageJson = new File(projectPath + '/package.json', false)
      packageJson.read().then( (packageJsonFile) =>
        parsedFile = JSON.parse(packageJsonFile)
        @changes = data.parseDependencies(parsedFile)
        this.updateDepTable(@changes)
        )

    this.setFileWatchTimer()



  setModalHandler: (modal, elem) ->
    modal_obj = modal
    modal_elem = elem
