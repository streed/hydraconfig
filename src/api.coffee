log4js = require 'log4js'
app = require('./app').app
crypto = require 'crypto'

Q = require 'q'
_ = require 'underscore'
LOG = log4js.getLogger 'api'

checkAuth = (req, res, next) ->
  if req.user
    return next()
  res.redirect "/login"

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

app.get '/api/view', (req, res) ->
  all = []
  app.zoo.getChildren '/configs', (err, children, stats) ->
    LOG.info "Getting data from all: ", children
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

app.get '/api/key/:userId', checkAuth, (req, res) ->
  app.db.OauthClient.findAll({where: {userId: req.params.userId}}).complete (err, clients) ->
    if err
      res.status(500).done()

    if clients
      res.send clients
    else
      res.send []
    
  
app.put '/api/key/new', checkAuth, (req, res) ->
  LOG.trace req.user
  app.db.OauthClient.count({where: {userId: req.body.userId}}).success (c) ->
    if c < 5
      crypto.randomBytes 12, (ex, buf) ->
        clientId = buf.toString 'hex'
        crypto.randomBytes 24, (ex, buf2) ->
          clientSecret = buf2.toString 'hex'
          app.db.OauthClient.create({
            clientId: clientId
            clientSecret: clientSecret
            redirect_uri: "http://fetch.conf"
          }).success (oauthClient) ->
            oauthClient.setUser(req.user).success (user) ->
              res.send oauthClient
    else
      res.send {}


