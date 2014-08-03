log4js = require 'log4js'
express = require 'express'
stylus = require 'stylus'
nib = require 'nib'
morgan = require 'morgan'
serveStatic = require 'serve-static'
bodyParser = require 'body-parser'
Q = require 'q'
_ = require 'underscore'
LOG = log4js.getLogger 'app.js'

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

exports.app = app

