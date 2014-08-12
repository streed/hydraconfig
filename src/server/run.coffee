log4js = require 'log4js'
app = require('./app').app
db = require('./db')
zookeeper = require 'node-zookeeper-client'

Q = require 'q'

api = require('./api').api
require './frontend'

client = require('redis').createClient()
limiter = require('express-limiter')(api, client)
app.use limiter(
  lookup: ['connection.remoteAddress', 'headers.x-forwarded-for']
  total: 500
  expire: 1000 * 60 * 60
  whitelist: (req) ->
    if req.session and req.session.accessToken
      true
    false
)

LOG = log4js.getLogger 'run'

Q.all([db.load]).then ->
  app.db = db.db
  app.use '/api', api
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
    app.zoo.zkBase = "/configs/"
