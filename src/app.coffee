log4js = require 'log4js'
express = require 'express'
stylus = require 'stylus'
nib = require 'nib'
morgan = require 'morgan'
serveStatic = require 'serve-static'
bodyParser = require 'body-parser'
zookeeper = require 'node-zookeeper-client'
Q = require 'q'
_ = require 'underscore'
LOG = log4js.getLogger 'app.js'

app = express()

compile = (str, path) ->
  return stylus(str)
    .set 'filename', path
    .use nib()

app.set 'views', __dirname + '/views'
app.set 'view engine', 'jade'
app.use stylus.middleware
  src: __dirname + '/public'
  compile: compile
app.use serveStatic __dirname + '/public'
app.use morgan 'short'
app.use bodyParser.json()
app.use bodyParser.urlencoded(
  extended: true
)

app.get "/", (req, res) ->
  res.render 'index',
    page: "New"
    conf: 'All'

app.get "/new", (req, res) ->
  res.render 'new',
    error: req.query.error
    message: req.query.message

app.post '/new', (req, res) ->
  if not /^[a-z0-9]+(-[a-z0-9]+)*$/ig.test req.body.configName
    res.redirect '/new?error=' + req.body.configName + '&message=Config name must start with a number or letter followed by one dash followed by one or more letters or numbers'
  else
    LOG.info "Checking if /configs/" + req.body.configName + " exists"
    app.zoo.exists '/configs' + req.body.configName, (err, stat) ->
      if err
        LOG.error err.stack

      if stat
        LOG.error req.body.configName + " exists"
      else
        LOG.info "Creating '/configs/" + req.body.configName + "'"
        data = JSON.stringify
          name: req.body.configName
          conf: []
        app.zoo.create "/configs/" + req.body.configName, new Buffer(data), (err, path) ->
          if err
            LOG.error err.stack

          if path
            LOG.info "Created new config '/configs/" + req.body.configName + "'"
            res.redirect '/view/' + req.body.configName
          else
            LOG.error "Could not create the path...for some reason."
            res.redirect '/new?error=' + req.body.configName + '&message=Could not create or exists already'


app.get '/view/:config', (req, res) ->
  res.render 'view',
    config: req.params.config

app.get '/api/view', (req, res) ->
  all = []
  app.zoo.getChildren '/configs', (err, children, stats) ->
    LOG.info "Getting data from all:" + children
    Q.allSettled(_.map(children, ((x) ->
      deferred = Q.defer()
      app.zoo.getData '/configs/' + x, (err, data, stat) ->
        if err
          LOG.error err

        if stat
          data = JSON.parse data.toString("utf8")
          deferred.resolve(data)

       return deferred.promise
    ))).then((results) ->
      for r in results
        all.push r.value

      res.send all
    ).done()
          

app.get '/api/view/:config', (req, res) ->
  config = req.params.config
  LOG.info "Getting /configs/" + config

  app.zoo.getData '/configs/' + config, (err, data, stat) ->
    if err
      LOG.error err.stack
      res.status 404

    if stat
      data = JSON.parse data.toString('utf8')
      res.send data
    else
      res.status 404

app.put '/api/view/:config', (req, res) ->
  config = req.params.config

  app.zoo.setData '/configs/' + config, new Buffer(JSON.stringify(req.body)), (err, stat) ->
    if err
      LOG.error err

    if stat
      res.send 200
    else
      res.send 500

server = app.listen 8080, ->
  LOG.info "Listening on: %s:%d", server.address().address, server.address().port
  LOG.info "Checking for the default zookeeper folder 'configs' exists"
  client = zookeeper.createClient "localhost:2181"
  client.once "connected", ->
    LOG.info 'connected to zookeeper'
    client.exists '/configs', (err, stat) ->
      if err
        LOG.error err.stack

      if stat
        LOG.info "'/configs' exists"
      else
        LOG.info "'/configs' does not exist...let's create it."
        client.create "/configs", new Buffer("root"), (err, path) ->
          if err
            LOG.error err.stack

          if path
            LOG.info "Created '/configs': {}", path
  client.connect()

  app.zoo = client


