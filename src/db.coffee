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
  token: Sequelize.STRING
  conf:Sequelize.STRING
)

Config = db.define("Config",
  maxKeys: Sequelize.INTEGER
  zkPath: Sequelize.STRING
  token: Sequelize.STRING
)

AuthCode = db.define("AuthCode",
  authCode: Sequelize.STRING
  clientId: Sequelize.STRING
  expires: Sequelize.DATE
  userId: Sequelize.INTEGER
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
  redirectUri: Sequelize.STRING
)

RefreshToken = db.define("RefreshToken",
  refreshToken: Sequelize.STRING
  clientId: Sequelize.STRING
  userId: Sequelize.INTEGER
  expires: Sequelize.DATE
)

User.hasMany Config
Config.belongsTo User

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

db.OauthModel = class OauthModel
  getAuthCode: (authCode, callback) ->
    AuthCode.find({where: {authCode: authCode}}).complete (err, authCode) ->
      if err
        return callback(err)

      callback null, authCode

  getAccessToken: (bearerToken, callback) ->
    AccessToken.find({where: {accessToken: bearerToken}}).complete (err, accessToken) ->
      if err
        return callback(err)
      
      callback null, accessToken

  getClient: (clientId, clientSecret, callback) ->
    OauthClient.find({where: {clientId: clientId}}).complete (err, client) ->
      if err
        return callback(err)
      
      return callback(null, client)

  getRefreshToken: (bearerToken, callback) ->
    RefreshTokens.find({where: {refreshToken: bearerToken}}).complete (err, refreshToken) ->
      if err
        return callback(err)
      return callback(null, refreshToken)

  getGrantType: (clientId, grantType, callback) ->
    if grantType == "authorization_code"
      return callback(null, true)
    return callback(null, false)

  saveAuthCode: (authCode, clientId, expires, user, callback) ->
    AuthCode.create(
      authCode: authCode
      clientId: clientId
      expires: expires
      user: user
    ).complete (err) ->
      callback(err)

  saveAccessToken: (accessToken, clientId, expires, userId, callback) ->
    AccessToken.create(
      accessToken: accessToken
      clientId: clientId
      userId: userId
      expires: expires
    ).complete (err) ->
      callback(err)

  saveRefreshToken: (refreshToken, clientId, userId, expires, callback) ->
    RefreshToken.create(
      refreshToken: refreshToken
      clientId: clientId
      userId: userId
      expires: expires
    ).complete (err) ->
      callback(err)

  getUser: (email, password, callback) ->
    User.find({where: {email: email}}).complete (err, user) ->
      if err
        return callback(err)

      callback(null, {userId: user.id})

load.resolve()
db.User = User
db.Config = Config
db.AccessToken = AccessToken
db.OauthClient = OauthClient
db.RefreshToken = RefreshToken

exports.db = db
exports.load = load.promise

