log4js = require 'log4js'
LOG = log4js.getLogger 'db'

Q = require 'q'
load = Q.defer()

Sequelize = require 'sequelize'
db = new Sequelize('fetchconf', 'root', '', {
  dialect: 'mysql'
  host: "localhost"
  pool: { maxConnections: 5, maxIdleTime: 30},
})

User = db.define("User",
  firstName: Sequelize.STRING
  lastName: Sequelize.STRING
  email: {
    type: Sequelize.STRING
    unique: true
    validators: {
      isEmail: true
    }
  }
  password: Sequelize.STRING
  zkChroot: {
    type: Sequelize.STRING
    unique: true
    validators: {
      len: 64
    }
  }
  active: {
    type: Sequelize.BOOLEAN
    defaultValue: false
  }
)

Role = db.define("Role",
  name: {
    type: Sequelize.STRING
    unique: true
  }
  description: Sequelize.STRING
)

UserPlan = db.define("UserPlan",
  start: Sequelize.DATE
  end: Sequelize.DATE
)

Plan = db.define("Plan",
  name: Sequelize.STRING
  price: Sequelize.DECIMAL
)

Config = db.define("Config",
  path: Sequelize.STRING
)

AccessToken = db.define("AccessToken",
  accessToken: {
    type: Sequelize.STRING
    unique: true
    validators: {
      len: 24
    }
  }
  expires: Sequelize.DATE
  session: {
    type: Sequelize.BOOLEAN
    defaultValue: false
  }
)

OauthClient = db.define("OauthClient",
  clientId: {
    type: Sequelize.STRING
    unique: true
    validators: {
      len: 24
    }
  }
  clientSecret: {
    type: Sequelize.STRING
    unique: true
    validators: {
      len: 48
    }
  }
  type: Sequelize.ENUM("internal", "public")
)

RefreshToken = db.define("RefreshToken",
  refreshToken: {
    type: Sequelize.STRING
    unique: true
    validators: {
      len: 24
    }
  }
  expires: Sequelize.DATE
)

User.hasMany Role
Role.belongsTo User

User.hasMany Config
Config.belongsTo User

User.hasOne UserPlan
UserPlan.belongsTo User

UserPlan.hasOne Plan
Plan.belongsTo UserPlan

User.hasMany AccessToken
AccessToken.belongsTo User

User.hasMany OauthClient
OauthClient.belongsTo User

User.hasMany RefreshToken
RefreshToken.belongsTo User

OauthClient.hasMany AccessToken
AccessToken.belongsTo OauthClient

OauthClient.hasMany RefreshToken
RefreshToken.belongsTo OauthClient

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
    if grantType == "client_credentials" or grantType == "refresh_token" or grantType == "password"
      return callback(null, true)
    return callback(null, false)

  saveAccessToken: (accessToken, clientId, expires, user, callback) ->
    AccessToken.create(
      accessToken: accessToken
      expires: expires
    ).success (token) ->
      token.setUser(user).success () ->
        db.OauthClient.find({where: {clientId: clientId}}).success (client) ->
          token.setOauthClient(client).success () ->
            callback null

  saveRefreshToken: (refreshToken, clientId, expires, user, callback) ->
    RefreshToken.create(
      refreshToken: refreshToken
      expires: expires
    ).success (token) ->
      token.setUser(user).success () ->
        db.OauthClient.find({where: {clientId: clientId}}).success (client) ->
          token.setOauthClient(client).success () ->
            callback null

###
db.dropAllSchemas().success( () ->
  db.sync(
    force: true
  ).success(() ->
    LOG.info 'Synched database'
    load.resolve()
  )
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

