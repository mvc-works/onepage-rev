
path = require 'path'
crypto = require 'crypto'
fs = require 'fs'

lodash = require 'lodash'
fsExtra = require 'fs-extra'

# store global configs
configs =
  htmlScaner: -> console.warn 'todo'
  cssScaner: -> console.warn 'todo'
  done: -> console.warn 'done rev, default log'

# global data
store =
  records: []
  basedir: null
  destdir: null
  wait: 0
  cdn: null

# due to the global data, only one task is capable
# to be refactored one day
exports.config = (options) ->
  lodash.assign configs, options

exports.run = (options) ->
  store.basedir = options.base
  store.destdir = path.join store.basedir, options.dest
  store.cdn = options.cdn
  processFile options.base, options.src

  # remove old files
  fsExtra.removeSync store.destdir

# use this function for get details of files and put in records
processFile = (base, name) ->
  fullpath = path.join base, name
  type = (path.extname name)[1..]
  # by now we only use those scaners, to be refactored
  scaner = switch type
    when 'html' then configs.htmlScaner
    when 'css' then configs.cssScaner
    else -> [] # search for nothing

  # read entry format in README
  entry =
    fullpath: fullpath
    # string in original file to be replaced
    replaceText: name
    # relative path to page root
    resolvedPath: path.relative store.basedir, fullpath
    # extname
    type: type
    # dependencies, in replaceText format, images use []
    children: []

  store.records.push entry
  # no promise here, so count numbers to detect finishing
  store.wait += 1

  digDependencies = ->
    for child in entry.children
      # resources in absolute path handled diffrently
      if child[0] is '/'
      then processFile store.basedir, child
      else processFile (path.dirname fullpath), child

  scanDependencies = (text) ->
    # results is an array of replaceText
    retults = scaner text
    entry.children = entry.children.concat retults

  # https://gist.github.com/jiyinyiyong/d00082eb5fceed2f8a16
  shasum = crypto.createHash('md5')
  s = fs.ReadStream entry.fullpath
  s.on 'data', (d) ->
    shasum.update d
    # use scaner for each piece
    scanDependencies String(d)
  s.on 'end', ->
    md5 = shasum.digest('hex')[...8]
    # hashPath has md5 in its name
    entry.hashPath = entry.resolvedPath.replace /(\.\w+)$/, ".#{md5}$1"
    digDependencies()
    store.wait -= 1
    # all resources are found
    if store.wait is 0
      copyApp()

  copyApp = ->
    store.records.forEach (entry) ->
      store.wait += 1
      # html file does not need md5 in filenane
      if entry.type is 'html'
        newPath = path.join store.destdir, entry.resolvedPath
      else
        newPath = path.join store.destdir, entry.hashPath
      fsExtra.ensureFile newPath, (error) ->
        if error?
          return console.error error
        src = fs.createReadStream entry.fullpath
        dest = fs.createWriteStream newPath
        # for file that has no dependencies, just copy
        if entry.children.length > 0
          src.on 'data', (chunk) ->
            text = String chunk
            for pattern in entry.children
              childEntry = lodash.find store.records, replaceText: pattern
              newUrl = "/#{childEntry.hashPath}"
              if store.cdn? then newUrl = store.cdn + newUrl
              # replace with md5 filenames
              text = text.replace pattern, newUrl
            newChunk = new Buffer text
            dest.write newChunk, 'utf8'
        else
          src.pipe dest
        src.on 'end', ->
          store.wait -= 1
          if store.wait is 0
            configs.done()
