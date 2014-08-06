log4js = require 'log4js'
app = require('./app').app
crypto = require 'crypto'

Q = require 'q'
_ = require 'underscore'
LOG = log4js.getLogger 'api'

app.get '/api/config/:config', app.passport.authenticate('bearer', {session: false}), (req, res) ->
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

app.put '/api/config/:config', app.passport.authenticate('bearer', {session: false}), (req, res) ->
  config = req.params.config
  conf = req.body

  for d in conf
    if !/[a-z0-9]+(\.[a-z0-9]+)*/i.test d.name
      res.status(500).end()
      return

  app.zoo.setData '/configs/' + config, new Buffer(JSON.stringify(req.body)), (err, stat) ->
    if err
      LOG.error err

    if stat
      res.status(200).end()
    else
      res.status(500).end()

app.get '/api/config', app.passport.authenticate('bearer', {session: false}), (req, res) ->
  all = []
  app.zoo.getChildren '/configs', (err, children, stats) ->
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

app.get '/api/key/:userId', app.passport.authenticate('bearer', {session: false}), (req, res) ->
  app.db.OauthClient.findAll({where: {userId: req.params.userId, type: "public"}}).complete (err, clients) ->
    if err
      res.status(500).done()

    if clients
      res.send clients
    else
      res.send []
    
  
app.put '/api/key/new', app.passport.authenticate('bearer', {session: false}), (req, res) ->
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

