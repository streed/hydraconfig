log4js = require 'log4js'
app = require('./app').app
crypto = require 'crypto'
express = require 'express'
api = express.Router()

Q = require 'q'
_ = require 'underscore'
LOG = log4js.getLogger 'api'

api.get '/config/:config', app.passport.authenticate('bearer', {session: false}), (req, res) ->
  config = req.params.config
  LOG.info "Getting /configs/" + config

  app.zoo.getData req.user.zkChroot + config, (err, data, stat) ->
    if err
      LOG.error err.stack
      res.status 404

    if stat
      data = JSON.parse data.toString('utf8')
      res.send data
    else
      res.status 404

api.put '/config/:config', app.passport.authenticate('bearer', {session: false}), (req, res) ->
  config = req.params.config
  conf = req.body

  for d in conf
    if !/[a-z0-9]+(\.[a-z0-9]+)*/i.test d.name
      res.status(500).end()
      return
  app.zoo.exists req.user.zkChroot.slice(0, -1), (err, stat) ->
    if err
      LOG.error err

    if stat
      app.zoo.setData req.user.zkChroot + config, new Buffer(JSON.stringify(req.body)), (err, stat) ->
        if err
          LOG.error err

        if stat
          res.status(200).end()
        else
          res.status(500).end()
    else
      app.zoo.create req.user.zkChroot + config, new Buffer(JSON.stringify(res.body)), (err, stat) ->
        if err
          LOG.error err

        if stat
          res.status(200).end()
        else
          res.status(500).end()

api.get '/config', app.passport.authenticate('bearer', {session: false}), (req, res) ->
  all = []
  app.zoo.getChildren req.user.zkChroot.slice(0, -1), (err, children, stats) ->
    Q.allSettled(_.map(children, ((x) ->
      deferred = Q.defer()
      app.zoo.getData req.user.zkChroot + x,( (err, data, stat) ->
        if err
          LOG.error err

        if stat
          data = JSON.parse data.toString("utf8")
          deferred.resolve(data)
      )
      return deferred.promise
    ))).then((results) ->
      for r in results
        all.push r.value
      res.send all
    ).done()

api.get '/key/:userId', app.passport.authenticate('bearer', {session: false}), (req, res) ->
  app.db.OauthClient.findAll({where: {userId: req.params.userId, type: "public"}}).complete (err, clients) ->
    if err
      res.status(500).done()

    if clients
      res.send clients
    else
      res.send []
    
  
api.put '/key/new', app.passport.authenticate('bearer', {session: false}), (req, res) ->
  app.db.OauthClient.count({where: {userId: req.body.userId, type:"public"}}).success (c) ->
    if c < 1
      crypto.randomBytes 12, (ex, buf) ->
        clientId = buf.toString 'hex'
        crypto.randomBytes 24, (ex, buf2) ->
          clientSecret = buf2.toString 'hex'
          app.db.OauthClient.create({
            clientId: clientId
            clientSecret: clientSecret
            type: "public"
          }).success (oauthClient) ->
            oauthClient.setUser(req.user).success (user) ->
              res.send oauthClient
    else
      res.send {}

api.get '/watch/:config', app.passport.authenticate('bearer', {session: false}), (req, res) ->
  config = req.params.config
  app.zoo.exists req.user.zkChroot + config, (err, stat) ->
    if err
      LOG.error err

    if stat
      app.zoo.getData req.user.zkChroot + config, ((event) ->
        app.zoo.getData req.user.zkChroot + config, (err, data, stat) ->
          res.send data
      ),((err, data, stat) ->
        LOG.info "Placed watcher"
      )

exports.api = api
