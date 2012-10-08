fs = require 'fs'
path = require 'path'
jsyaml = require 'js-yaml'
resolver = require 'js-yaml/lib/js-yaml/resolver'
less = require 'less'
inspect = require 'inspect'
json2yaml = require 'json2yaml'
app = (require 'flatiron').app

LESSVAR_TAG = 'tag:lesscss.org,variable'

resolver.Resolver.addImplicitResolver LESSVAR_TAG,
  /^\$\$?[\w-]+/,
  ['$']

logError = (e) ->
  if e.extract
    less.writeError e
  else
    app.log.error inspect e

build = (data, options, cb) ->
  new(less.Parser)({
    paths: [options.src.dir],
    filename: options.src.less
    }).parse data, (err, tree) ->
      if err
        logError e
        cb e

      try
        rulesets = tree.eval {frames: []}
      catch e
        logError e
        cb e

      jsyaml.addConstructor LESSVAR_TAG, (node) ->
        try
          lessv = new less.tree.Variable node.value.replace('$', '@')
          (lessv.eval {frames: [rulesets]}).toCSS()
        catch e
          logError e
          cb e

      doc = require options.src.yaml
      fs.writeFileSync options.out.yaml, json2yaml.stringify(doc), 'utf8'
      app.log.info 'Wrote', path.relative options.root, options.out.yaml

      css = tree.toCSS {compress: false}
      fs.writeFileSync options.out.css, css, 'utf8'
      app.log.info 'Wrote', path.relative options.root, options.out.css

      app.log.info 'Build ok'
      cb null

module.exports.run = (options, cb) ->
  if not cb
    cb = ->
  fs.readFile options.src.less, 'utf8', (e, data) ->
    if (e)
      cb e
    else
      build data, options, cb
