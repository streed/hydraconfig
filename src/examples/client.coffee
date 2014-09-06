Client = require('../client/client').Client

builder = Client.Builder()

c = null
builder.setClientId("4b06ff139b684d3a29851ef8")
  .setClientSecret("308746aa04248e3ae839052cd2c9be190652bc24ddcab5d4")
  .setApiUri("http://localhost:8080/")
  .build().then( (cc) ->
    cc.configs().then((configs) ->
      console.log configs
      cc.config("test", "test-overrides").then( (config) ->
        console.log config
      )
    )
  )
