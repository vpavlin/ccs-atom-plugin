$ = jQuery = require 'jquery'
{File} = require 'atom'
Data = require './data'


module.exports =
class RhCcsAtomModalPanel
  data = []
  constructor: (serializedState) ->
    # Create root element
    @element = document.createElement('div')
    @element.id = 'rh-ccs-atom-modal'

    data = new Data()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element

  showModal: (id) ->
    console.log "Showing details for #{id}"
    d = data.findInDeps(id)
    $(@element).focus()
    $(@element).html("")
    $(@element).append(@createLayout(d))

  constructGitStats: (d) ->
    @table = $("<table id='table-github'></table>")
    @table.append("<tr><th colspan=2>Github</th></tr>")
    @tbody = $("<tbody class='content'></tbody>")
    if d.metadata.git != undefined && d.metadata.git != null
      @tbody.append("<tr><td>Stars</td><td>#{d.metadata.git.stargazers_count}</td></tr>")
      @tbody.append("<tr><td>Forks</td><td>#{d.metadata.git.forks_count}</td></tr>")
      @tbody.append("<tr><td>Issues</td><td>#{d.metadata.git.opened_issues}/#{d.metadata.git.closed_issues}</td></tr>")
      @tbody.append("<tr><td>PRs</td><td>#{d.metadata.git.opened_prs}/#{d.metadata.git.closed_prs}</td></tr>")
    else
      @tbody.append("No Github stas found.")

    @table.append(@tbody)

    @table

  createLayout: (d) ->
    @score = data.countScore(d)
    @content = $("<div id='rh-ccs-atom-modal-main'></div>")
    @table = $("<table id='table-header'></table>")
    @table.append("<tr><th>Package</th><th>Version</th><th>License</th><th>Score</th></tr>")
    if d.metadata.manifest.license == undefined
      @em = "emphasize fail"
    else
      @em = "ok"

    @table.append("<tr><td>#{d.name}</td><td>#{d.cucosver}</td><td class='#{@em} license'>#{d.metadata.manifest.license}</td><td class='#{data.scoreToColor(@score)}'>#{@score}</td></tr>")
    @content.append(@table)


    @table = $("<table id='table-cves'></table>")
    @table.append("<tr><th colspan=2>CVEs</th></tr>")
    @tbody = $("<tbody class='content'></tbody>")
    if data.getCVEsLen(d) > 0
      for cve in d.metadata.CVEs
        @tbody.append("<tr><td class='cve-id'>#{cve['CVE-ID']}</td><td>#{cve.description}</td></tr>")
    else
      @tbody.append("No CVEs found")

    @table.append(@tbody)
    @content.append(@table)

    @content.append(@constructGitStats(d))

    if d.metadata.manifest.description != undefined
      @content.append("<table id='table-desc'><tr><th>Description</th></tr></tr><td><p>#{d.metadata.manifest.description}</p></td></tr></table>")

    @content
