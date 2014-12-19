
Onepage Rev
----

Clone files with MD5 hash in filenames before puroduction.

```
npm i --save-dev onepage-rev
```

```coffee
rev = require 'onepage-rev'
rev.config
  htmlScaner: ->
  cssScaner: ->
rev.run
  base: 'src/'
  src: 'index.html'
  dest: 'dist/'
# => returns a promise
```

### Demo

```coffee
rev = require 'onepage-rev'

rev.config
  htmlScaner: (text) ->
    collection = []
    match = text.match /([-\w\.\/]+)\.(css|js)(?=")/g
    collection.push match... if match?
    collection

  cssScaner: (text) ->
    collection = []
    r = /([-\w\.\/@]+)\.(css|jpg|png|woff|eot|ttf|svg)(?=('|\)))/g
    match = text.match r
    collection.push match... if match?
    collection

  done: ->

rev.run
  base: __dirname
  src: 'index.html'
  dest: './dist/'
  cdn: 'https://dn-demo.oss.aliyuncs.com'
```

### Details

Format of records:

```coffee
fullpath: ''
replaceText: '' # found by scaner to be replaced
resolvedPath: ''
hashPath: ''
type: '' # extension name
children: [
  # replaceText
]
```

### License

MIT