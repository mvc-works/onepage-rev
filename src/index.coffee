
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

exports.config = (options) ->
  lodash.assign configs, options

exports.run = (options) ->
  store.basedir = options.base
  store.destdir = path.join store.basedir, options.dest
  store.cdn = options.cdn
  processFile options.base, options.src

  fsExtra.removeSync store.destdir

processFile = (base, name) ->
  fullpath = path.join base, name
  type = (path.extname name)[1..]
  scaner = switch type
    when 'html' then configs.htmlScaner
    when 'css' then configs.cssScaner
    else -> [] # search for nothing

  entry =
    fullpath: fullpath
    replaceText: name
    resolvedPath: path.relative store.basedir, fullpath
    type: type
    children: []

  store.records.push entry
  store.wait += 1

  digDependencies = ->
    for child in entry.children
      if child[0] is '/'
      then processFile store.basedir, child
      else processFile (path.dirname fullpath), child

  scanDependencies = (text) ->
    retults = scaner text
    entry.children = entry.children.concat retults

  shasum = crypto.createHash('md5')
  s = fs.ReadStream entry.fullpath
  s.on 'data', (d) ->
    shasum.update d
    scanDependencies String(d)
  s.on 'end', ->
    md5 = shasum.digest('hex')[...8]
    entry.hashPath = entry.resolvedPath.replace /(\.\w+)$/, ".#{md5}$1"
    digDependencies()
    store.wait -= 1
    if store.wait is 0
      copyApp()

  copyApp = ->
    store.records.forEach (entry) ->
      store.wait += 1
      if entry.type is 'html'
        newPath = path.join store.destdir, entry.resolvedPath
      else
        newPath = path.join store.destdir, entry.hashPath
      fsExtra.ensureFile newPath, (error) ->
        if error?
          return console.error error
        src = fs.createReadStream entry.fullpath
        dest = fs.createWriteStream newPath
        if entry.children.length > 0
          src.on 'data', (chunk) ->
            text = String chunk
            for pattern in entry.children
              childEntry = lodash.find store.records, replaceText: pattern
              newUrl = "/#{childEntry.hashPath}"
              if store.cdn? then newUrl = store.cdn + newUrl
              text = text.replace pattern, newUrl
            newChunk = new Buffer text
            dest.write newChunk, 'utf8'
        else
          src.pipe dest
        src.on 'end', ->
          store.wait -= 1
          if store.wait is 0
            configs.done()
