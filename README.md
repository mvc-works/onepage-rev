
Onepage Rev
----

Clone files with MD5 hash in filenames before puroduction.

```
npm i --save-dev onepage-rev
```

### Demo

```coffee
rev = require 'onepage-rev'

rev.config
  # required, use RegExp to find recources in HTML
  htmlScaner: (text) ->
    collection = []
    match = text.match /([-\w\.\/]+)\.(css|js)(?=")/g
    collection.push match... if match?
    collection

  # required, use RegExp to find recources in CSS
  cssScaner: (text) ->
    collection = []
    r = /([-\w\.\/@]+)\.(css|jpg|png|woff|eot|ttf|svg)(?=('|\)))/g
    match = text.match r
    collection.push match... if match?
    collection

  done: ->
    # you can cb gulp task here

rev.run
  base: __dirname
  src: 'index.html'
  # dest is relative to base
  dest: './dist/'
  # when cdn is left undefined, `/` will be used
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