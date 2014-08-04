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

Client = db.define("Client",
  name: Sequelize.STRING
  clientId: Sequelize.STRING
  clientSecret: Sequelize.STRING
)

Token = db.define("Token",
  token: Sequelize.STRING
)

User.hasMany Config
Config.belongsTo User
User.hasMany Client
User.hasMany Token
Token.hasOne User

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

exports.db = db
exports.load = load.promise
