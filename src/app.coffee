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

BearerStrategy = require('passport-http-bearer').Strategy
LocalStrategy = require('passport-local').Strategy

Q = require 'q'
_ = require 'underscore'
LOG = log4js.getLogger 'app'

app = express()

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
app.use bodyParser.json()
app.use bodyParser.urlencoded(
  extended: true
)

app.use session({secret: "lol"})
app.use passport.initialize()
app.use passport.session()

app.db = require './db'

passport.use new BearerStrategy((token, done) ->
  app.db.User.find({where: {token: token}}).complete((err, user) ->
    LOG.info "auth ", err, user
    if err
      return done(err)
    if not user
      return done null, false
    return done( null, user,
      scope: 'read/write'
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
  LOG.info "serializeUser ", user.id
  return done(null, user.id)

passport.deserializeUser (id, done) ->
  app.db.User.find({where: {id: id}}).complete((err, user) ->
    LOG.info "deserializeUser ", id
    if err
      return done(err)
    if not user
      return done(null, false)
    return done(null, user)
  )

app.passport = passport
exports.app = app

