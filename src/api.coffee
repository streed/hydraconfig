log4js = require 'log4js'
app = require('./app').app

Q = require 'q'
_ = require 'underscore'
LOG = log4js.getLogger 'api'

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

app.get '/api/state', (req, res) ->
  state = app.zoo.getState()
  id = app.zoo.getSessionId()
  pass = app.zoo.getSessionPassword()
  timeout = app.zoo.getSessionTimeout()

  res.send
    state: state
    id: id.toString("hex")
    pass: pass.toString("hex")
    timeout: timeout

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

