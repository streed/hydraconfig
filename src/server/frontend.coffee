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
  if req.user
    res.redirect '/configs'
  else
    res.render 'index'

app.get '/register', (req, res) ->
  res.render 'register',
    error: req.query.error
    message: req.query.message

app.post '/register', (req, res) ->
  sha1 = crypto.createHash('sha1')
  user = req.body
  password = sha1.update(user.password)
  crypto.randomBytes 12, (ex, chroot) ->
    app.db.User.create(
      email: user.email
      password: password.digest('hex')
      firstName: user.firstName
      lastName: user.lastName
      zkChroot: app.zoo.zkBase + chroot.toString('hex') + "/"
    ).success( (user) ->
      crypto.randomBytes 12, (ex, buf) ->
        clientId = buf.toString 'hex'
        crypto.randomBytes 24, (ex, buf2) ->
          clientSecret = buf2.toString 'hex'
          app.db.OauthClient.create({
            clientId: clientId
            clientSecret: clientSecret
            type: "internal"
          }).success (oauthClient) ->
            oauthClient.setUser(user).success (client) ->
              app.zoo.create user.zkChroot.slice(0, -1), new Buffer(JSON.stringify({"total": 0, "configs": {}})), (err, stat) ->
                if err
                  LOG.error err

                if stat
                  res.redirect '/login'
                else
                  LOG.error stat
    ).error( (errors) ->
      if errors.code == 'ER_DUP_ENTRY'
        res.redirect '/register?error=Could not Register&message=Are you already registered?'
    )

app.get '/login', (req, res) ->
  if req.user
    res.redirect '/configs'
  res.render 'login',
    error: req.query.error
    message: req.query.message

app.post '/login', app.passport.authenticate('local', {successRedirect: '/configs', failureRedirect: '/login?error=Could not Login&message=Email or Password were invalid.'})

app.get '/logout', checkAuth, (req, res) ->
  app.db.AccessToken.destroy({accessToken: req.session.accessToken, session: true}).success () ->
    req.logout()
    req.session.accessToken = null
    res.redirect '/login'

app.get '/configs', checkAuth, (req, res) ->
  res.render 'configs',
    error: req.query.error
    message: req.query.message

app.post '/configs', checkAuth, (req, res) ->
  if not /^[a-z0-9]+(-[a-z0-9]+)*$/ig.test req.body.configName
    res.redirect '/configs?error=' + req.body.configName + '&message=Config name must follow the following format: ^[a-z0-9]+(-[a-z0-9]+)*$'
  else
    LOG.info "Checking if " + req.user.zkChroot + req.body.configName + " exists"
    app.zoo.exists req.user.zkChroot + req.body.configName, (err, stat) ->
      if err
        LOG.error err.stack

      if stat
        LOG.error req.body.configName + " exists"
      else
        LOG.info "Creating " + req.user.zkChroot + req.body.configName + "'"
        data = JSON.stringify
          name: req.body.configName
          conf: []
        app.zoo.create req.user.zkChroot + req.body.configName, new Buffer(data), (err, path) ->
          if err
            LOG.error err.stack

          if path
            LOG.info "Created new config '/configs/" + req.body.configName + "'"
            res.redirect '/configs/' + req.body.configName
          else
            LOG.error "Could not create the path...for some reason."
            res.redirect '/configs?error=' + req.body.configName + '&message=Could not create or exists already'


app.get '/configs/:config', checkAuth, (req, res) ->
  if /^[a-z0-9]+(-[a-z0-9]+)*$/ig.test req.params.config
    res.render 'view',
      config: req.params.config
  else
    res.status(500).end()

app.get '/access', checkAuth, (req, res) ->
  res.render 'access',
    user: req.user

