Client = require('../client/client').Client

builder = Client.Builder()

c = null
builder.setClientId("9cfa8712468e948b6a95d7a2")
  .setClientSecret("990c37aec11cb6acf244073c036873d0bfccd5607b061ac1")
  .setApiUri("http://hydraconfig.com/")
  .build().then( (cc) ->
    cc.configs().then((configs) ->
      console.log configs
      cc.config("prod").then( (config) ->
        console.log config
      )
    )
  )
