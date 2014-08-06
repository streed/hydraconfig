log4js = require 'log4js'
express = require 'express'
session = require 'express-session'
stylus = require 'stylus'
nib = require 'nib'
morgan = require 'morgan'
serveStatic = require 'serve-static'
bodyParser = require 'body-parser'
passport = require 'passport'
crypto = require 'crypto'
oauthserver = require 'node-oauth2-server'

BearerStrategy = require('passport-http-bearer').Strategy
LocalStrategy = require('passport-local').Strategy

Q = require 'q'
_ = require 'underscore'
LOG = log4js.getLogger 'app'

app = express()
app.use bodyParser.urlencoded(
  extended: true
)
app.use bodyParser.json()

app.db = require './db'

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

app.use session({secret: "lol"})
app.use passport.initialize()
app.use passport.session()

app.oauth = oauthserver(
  model: new app.db.db.OauthModel
  grants: ["password", "client_credentials", "refresh_token"]
  debug: true
)

app.all '/oauth/token', app.oauth.grant()
app.use app.oauth.errorHandler()

app.use (req, res, next) ->
  if req.url.indexOf("api") >= 0
    return next()
    
  if !(req.user)
    return next()
  if req.session.accessToken
    res.locals.accessToken = req.session.accessToken
    return next()
  else
    crypto.randomBytes 24, (ex, buf) ->
      accessToken = buf.toString('hex')
      app.db.OauthClient.find({where: {userId: req.user.id, type: "internal"}}).complete (err, client) ->
        if err
          return next()

        if client
          app.db.AccessToken.create(
            accessToken: accessToken
            expires: new Date(Date.now() + 3600000)
            session: true
          ).success (token) ->
            token.setUser(req.user).success () ->
              token.setOauthClient(client).success () ->
                req.session.accessToken = accessToken
                res.locals.accessToken = accessToken
                return next()
        else
          return next()

passport.use new BearerStrategy((token, done) ->
  app.db.AccessToken.find({where: {accessToken: token}}).complete((err, token) ->
    if err
      return done(err)
    if not token
      return done null, false

    token.getUser().success( (user) ->
      return done( null, user,
        scope: 'read/write'
      )
    )
  )
)

passport.use new LocalStrategy((email, password, done) ->
  sha1 = crypto.createHash('sha1')
  password = sha1.update(password).digest('hex')
  app.db.User.find({where: {email: email}}).complete((err, user) ->
    if err
      LOG.trace "Err: ", err
      return done(err)
    if user and user.password != password
      LOG.trace "Wrong password"
      return done(null, false)
    return done( null, user)
  )
)

passport.serializeUser (user, done) ->
  return done(null, user.id)

passport.deserializeUser (id, done) ->
  app.db.User.find({where: {id: id}}).complete((err, user) ->
    if err
      return done(err)
    if not user
      return done(null, false)
    return done(null, user)
  )

app.passport = passport
exports.app = app

