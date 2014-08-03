log4js = require 'log4js'
app = require('./app').app

Q = require 'q'
_ = require 'underscore'
LOG = log4js.getLogger 'frontend'

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
    res.redirect '/new?error=' + req.body.configName + '&message=Config name must follow the following format: ^[a-z0-9]+(-[a-z0-9]+)*$'
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

app.get '/state', (req, res) ->
  res.render 'state'
