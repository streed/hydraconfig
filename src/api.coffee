log4js = require 'log4js'
app = require('./app').app
crypto = require 'crypto'
express = require 'express'
api = express.Router()

Q = require 'q'
_ = require 'underscore'
LOG = log4js.getLogger 'api'

# This endpoint takes a comma seperated list and composes a complete configuration from this list
# in a left to right ordering.
#
#  @example CURL to get qa and prod mixed config 
#   curl /api/config/qa,prod -H "Authorization: Bearer ..."
#
# @param config comma seperated list of configuration names.
api.get '/config/:config', app.passport.authenticate('bearer', {session: false}), (req, res) ->
  config = req.params.config
  LOG.info "Getting /configs/" + config
  config = config.split(',')

  all = []
  Q.allSettled(_.map(config, ((x) ->
    deferred = Q.defer()
    app.zoo.getData req.user.zkChroot + x,( (err, data, stat) ->
      if err
        LOG.error err
        res.status(500).end()

      if stat
        data = JSON.parse data.toString("utf8")
        deferred.resolve(data)
      else
        res.status(404).end()
    )
    return deferred.promise
  ))).then((results) ->
    result = {}
    for name in config
      for r in results
        r = r.value
        if name == r.name
          for k in r.conf
            result[k.name] = k.value
    res.send result
  ).done()

# Updates the specified configuration's key/value parings. If a key exists already then it's value
# is overwritten by the new value. If the config does not exist then one is created.
#
# @param config string The name of a configuration file in the database.
# @param body json The json list that contains name/value tuples. The names of the tuples must be
#   matched by the following regex: /[a-z0-9]+(\.[a-z0-9]+)*/i
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

# Retruns a JSON list that contains all of the configurations that the user owns.
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

# This places a watch on the specified config. What this means is that a Long Polling connection is created,
# please make sure the client supports long-polling, and if a value is changed in the config then the client
# will be notified immediately and the new configuration data will be returned to the connecting client.
#
# @note Long-Polling was choosen to ease in the creation of new clients of this API.
#
# @param config string The name of a config.
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

# Internal API that is used to return the current public API key for the currently registered user.
# 
# @param userId integer The integer for the registered user.
api.get '/key/:userId', app.passport.authenticate('bearer', {session: false}), (req, res) ->
  app.db.OauthClient.findAll({where: {userId: req.params.userId, type: "public"}}).complete (err, clients) ->
    if err
      res.status(500).done()

    if clients
      res.send clients
    else
      res.send []
    
# Internal API that is used to create the users public API key.
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

exports.api = api
