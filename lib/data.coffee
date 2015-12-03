$ = jQuery = require 'jquery'

module.exports =
class Data
  deps = []
  constructor: () ->
    console.log "Constructing data object"

  parseDependencies: (pkg) ->
    @changes = {"added": [], "removed": []}
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
      d.metadata = undefined
      if @findInDeps(d.id) == false
        @changes.added.push(d.id)
        deps.push(d)

    for i,dep of deps
      console.log pkg["dependencies"][dep.name]
      if pkg["dependencies"][dep.name] != undefined && pkg["dependencies"][dep.name] == dep.pkgver
        continue

      @changes.removed.push(dep.id)
      deps.splice(i, 1)

    #console.log "Deps" +deps
    @changes

  findInDeps: (id) ->
    ret = false
    for dep in deps
      if dep.id == id
        ret = dep
        break
    ret

  nvrToId: (orig_name, orig_ver) ->
    ver = orig_ver.replace(/\./g, "-")
    name = orig_name.replace(/\./g, "-")
    "#{name}-#{ver}"

  getDeps: ->
    deps

  getCVEsLen: (d) ->
    res = 0
    if d.metadata != undefined && d.metadata.CVEs != undefined
      res = d.metadata.CVEs.length

    res

  countScore: (d) ->
    if d.metadata == undefined
      return "N/A"

    @score = 100
    if d.metadata.manifest.license == undefined
      @score -= 10

    @cve_len = @getCVEsLen(d)
    @score -= @cve_len * 30
    if d.metadata.manifest.author == undefined || d.metadata.manifest.author == ""
      @score -= 5

    if d.metadata.manifest.scripts == undefined || d.metadata.manifest.scripts.tests == undefined || d.metadata.manifest.scripts.tests == ""
      @score -= 5

    if d.metadata.manifest.description == undefined
      @score -= 5

    if d.metadata.git == undefined || d.metadata.git == null
      @score -=15
    else
      if parseInt(d.metadata.git.closed_issues) != 0
        @score -= (parseInt(d.metadata.git.opened_issues)/parseInt(d.metadata.git.closed_issues)-1)*10
      if parseInt(d.metadata.git.stargazers_count) > 500
        @score += 2
      else if parseInt(d.metadata.git.stargazers_count) == 0
        @score -=5
      if parseInt(d.metadata.git.closed_prs) != 0
        @score -= (parseInt(d.metadata.git.opened_prs)/parseInt(d.metadata.git.closed_prs)-1)*10

    res = 0
    if @score > 100
      res = 100
    else if @score < 0
      res = 0
    else
      res = parseInt(@score)

    res

  scoreToColor: (score) ->
    if score > 75
      "green"
    else if score > 50 && score <= 75
      "orange"
    else
      "red"
