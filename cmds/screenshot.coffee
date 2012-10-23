util = require 'util'
fs = require 'fs'
path = require 'path'
async = require 'async'
phantom = require 'phantom'
app = (require 'flatiron').app

renderUrl = (page, url, filename, cb) ->
  page.open url, (status) ->
    if status == 'fail'
      app.log.error 'Error opening', url
      cb(status)
    else
      page.render filename, () ->
        app.log.info path.relative process.cwd(), filename
        cb()

module.exports.run = (options, cb) ->
  if not cb
    cb = ->

  if not fs.existsSync options.screenshot.dir
    fs.mkdirSync options.screenshot.dir

  phantom.create (ph) ->
    ph.createPage (page) ->
      page.set 'viewportSize',
        width: 512

      renderSample = (name, itcb) ->
        url = util.format 'http://localhost:%d/t/%s#noscript', options.port.screenshot, name
        filename = path.join options.screenshot.dir, name + '.png'
        renderUrl page, url, filename, itcb

      async.forEachSeries ['console', 'server', 'channel'], renderSample, () ->
        ph.exit()
        cb()
