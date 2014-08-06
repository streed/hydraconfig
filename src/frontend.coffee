log4js = require 'log4js'
app = require('./app').app
crypto = require 'crypto'

Q = require 'q'
_ = require 'underscore'
LOG = log4js.getLogger 'frontend'

checkAuth = (req, res, next) ->
  if req.user
    return next()
  res.redirect "/login"

app.get '/', (req, res) ->
  res.render 'index'

app.get '/register', (req, res) ->
  res.render 'register'

app.post '/register', (req, res) ->
  sha1 = crypto.createHash('sha1')
  user = req.body
  password = sha1.update(user.password)
  app.db.User.create(
    email: user.email
    password: password.digest('hex')
    firstName: user.firstName
    lastName: user.lastName
  ).success (user) ->
    crypto.randomBytes 12, (ex, buf) ->
      clientId = buf.toString 'hex'
      crypto.randomBytes 24, (ex, buf2) ->
        clientSecret = buf2.toString 'hex'
        app.db.OauthClient.create({
          clientId: clientId
          clientSecret: clientSecret
          type: "internal"
        }).success (oauthClient) ->
          oauthClient.setUser(user).success (user) ->
            res.redirect '/login'

app.get '/login', (req, res) ->
  if req.user
    res.redirect '/configs'
  res.render 'login'

app.post '/login', app.passport.authenticate('local', {successRedirect: '/configs', failureRedirect: '/login'})

app.get '/logout', checkAuth, (req, res) ->
  req.logout()
  res.redirect '/'

app.get '/configs', checkAuth, (req, res) ->
  res.render 'configs'

app.get "/configs/new", checkAuth, (req, res) ->
  res.render 'new',
    error: req.query.error
    message: req.query.message

app.post '/configs/new', checkAuth, (req, res) ->
  if not /^[a-z0-9]+(-[a-z0-9]+)*$/ig.test req.body.configName
    res.redirect '/configs/new?error=' + req.body.configName + '&message=Config name must follow the following format: ^[a-z0-9]+(-[a-z0-9]+)*$'
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


app.get '/configs/:config', checkAuth, (req, res) ->
  res.render 'view',
    config: req.params.config

app.get '/access', checkAuth, (req, res) ->
  res.render 'access',
    user: req.user

