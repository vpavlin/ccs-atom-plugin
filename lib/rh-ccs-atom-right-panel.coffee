$ = jQuery = require 'jquery'
fs = require 'fs'
#require 'jquery-ui'
io = require 'socket.io-client'
{File} = require 'atom'


module.exports =
class RhCcsAtomRightPanel
  deps = []
  timers = {}
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
    $(@element).append(table)

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element

  updateDepTable: ()->
    console.log(deps)
    content = $('<tbody>')
    for dep in deps
      if $("#rh-ccs-dep-table ##{dep.id}").html() == undefined
        content.append("<tr id='#{dep.id}'><td>#{dep.name}</td><td>#{dep.pkgver}</td><td>Loading...</td></tr>")
        @checkCucos(dep)
      else
        @button = $("#rh-ccs-dep-table ##{dep.id} .analyze")
        if $(@button).html() != undefined
          console.log "Checking #{dep.name} again"
          @checkCucos(dep)

    $('#rh-ccs-dep-table').append(content)

  updateStatusBar: () ->
    console.log "Updating Status Bar"
    @bar = $("#rh-ccs-status-bar")
    if $(@bar).html() == undefined or $(@bar).html() == "Loading..."
      setTimeout(@updateStatusBar, 500)
      return

    @analyzed = 0
    @to_analyze = 0
    @some_undefined = false
    for dep in deps
      if dep.analyzed == true
        @analyzed++
      else if dep.analyzed == false
        @to_analyze++
      else if dep.analyzed == undefined
        @some_undefined = true

    @text = ""
    @orig_color = $(@bar).attr('data-color')
    @color = @orig_color
    if !@some_undefined
      if @to_analyze == 0
        @text = "You are all good! (All #{@analyzed} deps ok)"
        @color = "green"
      else if @analyzed == 0
        @text = "Ugh, this is terrible (All #{@to_analyze} deps not analyzed)"
        @color = "red"
      else
        @text = "#{@to_analyze} deps to analyze (#{@analyzed} deps analyzed)"
        @color = "orange"

      $(@bar).html(@text).removeClass(@orig_color).attr('data-color', @color).addClass(@color)

  nvrToId: (orig_name, orig_ver) ->
    ver = orig_ver.replace(/\./g, "-")
    name = orig_name.replace(/\./g, "-")
    "#{name}-#{ver}"

  findInDeps: (id) ->
    ret = false
    for dep in deps
      if dep.id == id
        ret = dep
        break
    ret

  cucosResponse: (self, id, data) ->
    $("#rh-ccs-dep-table ##{id}").find("td").last().html("<a href='##{id}' class='detail'>Detail</a>")
    @updateStatusBar()
    if timers[id] != undefined
      clearInterval(timers[id])
      delete timers[id]

  cucosAnalyzeRequest: (id) ->
    self = this
    dep = @findInDeps(id)
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
    id = @nvrToId(pkg.name, pkg.cucosver)
    $.get(uri, (data) ->
      pkg.analyzed = true
      self.cucosResponse(self, id, data)
      ).fail( () ->
        pkg.analyzed = false
        self.cucosNotFound(self, id)
      )

  parseDependencies: (pkg) ->
    for dep, ver of pkg['dependencies']
      d = {}
      d.name = dep
      d.pkgver = ver
      if ver.substr(0,1) == "^"
        d.cucosver = ver.substr(1, ver.length)
      else
        d.cucosver = ver
      d.id = @nvrToId(d.name, d.cucosver)
      d.analyzed = undefined
      if @findInDeps(d.id) == false
        deps.push(d)

    deps

  updateDependencies: ->
    projectPath = atom.project.getPaths()[0]
    console.log projectPath
    isPackageJson = atom.project.contains(projectPath + '/package.json')
    if isPackageJson
      packageJson = new File(projectPath + '/package.json', false)
      packageJson.read().then( (packageJsonFile) =>
        parsedFile = JSON.parse(packageJsonFile)
        this.parseDependencies(parsedFile)
        this.updateDepTable()
        )
