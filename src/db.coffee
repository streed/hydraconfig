log4js = require 'log4js'
LOG = log4js.getLogger 'db'

Q = require 'q'
load = Q.defer()

Sequelize = require 'sequelize'
db = new Sequelize('fetchconf', 'root', 'root', {
  dialect: 'sqlite'
  storage: '/tmp/fetchconf.sqlite'
})

User = db.define("User",
  firstName: Sequelize.STRING
  lastName: Sequelize.STRING
  email: Sequelize.STRING
  password: Sequelize.STRING
  conf:Sequelize.STRING
)

Config = db.define("Config",
  maxKeys: Sequelize.INTEGER
  zkPath: Sequelize.STRING
  token: Sequelize.STRING
)

AccessToken = db.define("AccessToken",
  accessToken: Sequelize.STRING
  clientId: Sequelize.STRING
  userId: Sequelize.INTEGER
  expires: Sequelize.DATE
)

OauthClient = db.define("OauthClient",
  clientId: Sequelize.STRING
  clientSecret: Sequelize.STRING
  type: Sequelize.ENUM("internal", "public")
)

RefreshToken = db.define("RefreshToken",
  refreshToken: Sequelize.STRING
  clientId: Sequelize.STRING
  userId: Sequelize.INTEGER
  expires: Sequelize.DATE
)

User.hasMany Config
Config.belongsTo User

OauthClient.belongsTo User

db.OauthModel = class OauthModel
  getAccessToken: (bearerToken, callback) ->
    AccessToken.find({where: {accessToken: bearerToken}}).complete (err, accessToken) ->
      if err
        return callback(err)
      
      callback null, accessToken

  getClient: (clientId, clientSecret, callback) ->
    OauthClient.find({where: {clientId: clientId, clientSecret: clientSecret}}).complete (err, client) ->
      if err
        return callback(err)
      
      return callback(null, client)

  getRefreshToken: (bearerToken, callback) ->
    RefreshToken.find({where: {refreshToken: bearerToken}}).complete (err, refreshToken) ->
      if err
        return callback(err)

      return callback(null, refreshToken)

  getUserFromClient: (clientId, clientSecret, callback) ->
    OauthClient.find({where: {clientId: clientId, clientSecret: clientSecret}}).complete (err, client) ->
      if err
        return callback(err)
      client.getUser().success (user) ->
        return callback(null, user)

  grantTypeAllowed: (clientId, grantType, callback) ->
    if grantType == "client_credentials" or grantType == "refresh_token"
      return callback(null, true)
    return callback(null, false)

  saveAccessToken: (accessToken, clientId, expires, user, callback) ->
    AccessToken.create(
      accessToken: accessToken
      clientId: clientId
      userId: user.id
      expires: expires
    ).complete (err) ->
      callback(err)

  saveRefreshToken: (refreshToken, clientId, expires, user, callback) ->
    RefreshToken.create(
      refreshToken: refreshToken
      clientId: clientId
      userId: user.id
      expires: expires
    ).complete (err) ->
      callback(err)

###
db.sync(
  force: true
).complete((err) ->
  if err
    LOG.error err
  else
    LOG.info 'Synched database'
    load.resolve()
)
###
load.resolve()

db.User = User
db.Config = Config
db.AccessToken = AccessToken
db.OauthClient = OauthClient
db.RefreshToken = RefreshToken

exports.db = db
exports.load = load.promise

