log4js = require 'log4js'
request = require 'request'
Q = require 'q'

class Client
  LOG = log4js.getLogger("client")

  class InnerBuilder
    constructor: () ->
      @_clientId = ""
      @_clientSecret = ""
      @_apiUri = "https:/hydraconfig.com/"

    setClientId: (@_clientId) ->
      @

    setClientSecret: (@_clientSecret) ->
      @
    
    setApiUri: (@_apiUri) ->
      @

    build: () ->
      client = new Client(@_clientId, @_clientSecret, @_apiUri)
      return client.auth()

  @Builder: () ->
    return new InnerBuilder

  constructor: (@_clientId, @_clientSecret, @_apiUri) ->

  auth: () ->
    authDeferred = Q.defer()
    data = {
      grant_type: "client_credentials"
      client_id: @_clientId
      client_secret: @_clientSecret
    }
    self = @
    request.post @_apiUri + "oauth/token", {form: data}, (err, response, body) ->
      body = JSON.parse body
      self._accessToken = body.access_token
      self._refreshToken = body.refresh_token
      authDeferred.resolve(self)
    return authDeferred.promise

  configs: () ->
    configsDeferred = Q.defer()
    url = @_apiUri + "api/config"
    request.get {url: url, headers: { "Authorization": "Bearer "+@_accessToken}}, (err, resp, body) ->
      body = JSON.parse body
      configsDeferred.resolve(body)
    return configsDeferred.promise

  config: (name...) ->
    configsDeferred = Q.defer()
    name = name.join(",")
    url = @_apiUri + "api/config/" + name
    request.get {url: url, headers: { "Authorization": "Bearer "+@_accessToken}}, (err, resp, body) ->
      body = JSON.parse body
      configsDeferred.resolve(body)
    return configsDeferred.promise

exports.Client = Client
