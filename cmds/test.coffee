fs = require 'fs'
events = require 'events'
path = require 'path'
plates = require 'plates'
ecstatic = require 'ecstatic'
flatiron = require 'flatiron'
app = flatiron.app

broadcaster = new events.EventEmitter

readFileSync = (file) ->
  try
    return fs.readFileSync(file, 'utf8')
  catch e
    return ''

platesMap = new plates.Map
platesMap.where('id').is('css-default').use('defaultcss').as('href')
platesMap.where('id').is('css-theme').use('themecss').as('href')
platesMap.where('id').is('js-helper').use('helperjs').as('src')

initEventStream = (req, res) ->
  res.writeHead 200,
      'Content-Type': 'text/event-stream'
      'Cache-Control': 'no-cache'
      'Connection': 'keep-alive'
      'X-Accel-Buffering': 'no' # disable nginx proxy buffering
      'Access-Control-Allow-Origin': req.headers.origin # for XDomainRequest

  # padding for IE and Chrome
  res.write (new Array(2048)).join(' ') + '\n\n'
  app.log.info 'Connected'

module.exports.plugin =
  name: 'limechat'
  attach: (options) ->
    platesData =
      defaultcss: '/fixtures/default.css',
      themecss: '/' + options.theme + '.css'
      helperjs: '/fixtures/helper.js'

    app.use flatiron.plugins.http

    # serve html
    app.router.get '/t/:fixture', (fixture) ->
      @res.writeHead 200,
        'Content-Type': 'text/html'
      templatePath = path.join options.fixture.dir, fixture + '.html'
      html = readFileSync templatePath
      @res.write plates.bind(html, platesData, platesMap)
      @res.end()

    # reloader
    options.emitter.on 'reload', () ->
      broadcaster.emit 'publish', 'reload'

    app.router.get '/eventsource', () ->
      req = @req
      res = @res
      initEventStream req, res

      pusher = (event) ->
        app.log.info 'Sending event:', event
        res.write 'event: ' + event + '\n'
        res.write 'data: \n\n'

      remover = () ->
        app.log.info 'Disconnected'
        broadcaster.removeListener 'publish', pusher

      broadcaster.on 'publish', pusher
      # req.request is the raw request object
      req.request.on 'close', remover

    # alias /[theme]/static/images/image.png
    resource_dir = path.join options.root, 'static'
    resourceMiddleware = ecstatic resource_dir
    app.router.get '/' + options.theme + '/static/:dir/:filename', (dir, filename) ->
      @req.url = '/' + (path.join dir, filename)
      resourceMiddleware @req, @res, @next

    # catch-all static files handler
    app.http.before.push ecstatic options.root
    app.http.before.push ecstatic options.libroot
