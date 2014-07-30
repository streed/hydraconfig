log4js = require 'log4js'
express = require 'express'
stylus = require 'stylus'
nib = require 'nib'
morgan = require 'morgan'
serveStatic = require 'serve-static'
bodyParser = require 'body-parser'
zookeeper = require 'node-zookeeper-client'
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
    confs: [
      {
        name: 'dev'
        conf: [
          {
            parent: 'dev'
            name: 'api'
            value: 'http://api.pro.fetchconf.com'
          },
          {
            parent: 'dev'
            name: 'mongo'
            value: 'localhost:2717'
          }
        ]
      },
      {
        name: 'prod'
        conf: [
          {
            parent: 'dev'
            name: 'api'
            value: 'http://api.pro.fetchconf.com'
          },
          {
            parent: 'dev'
            name: 'mongo'
            value: 'localhost:2717'
          },
          {
            parent: 'prod'
            name: 'email'
            value: 'http://email.dev.fetchconf.com'
          }
        ]
      }
    ]

app.get "/new", (req, res) ->
  res.render 'new'

app.post '/new', (req, res) ->
  LOG.info "Checking if /configs/" + req.body.configName + " exists"
  app.zoo.exists '/configs' + req.body.configName, (err, stat) ->
    if err
      LOG.error err.stack

    if stat
      LOG.error req.body.configName + " exists"
    else
      LOG.info "Creating '/configs/" + req.body.configName + "'"
      app.zoo.create "/configs/" + req.body.configName, new Buffer(JSON.stringify({})), (err, path) ->
        if err
          LOG.error err.stack

        if path
          LOG.info "Create new config '/configs/" + req.body.configName + "'"
    res.render 'new'


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


