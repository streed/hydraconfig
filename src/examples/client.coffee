Client = require('../client/client').Client

builder = Client.Builder()

builder.setClientId("8a1143fe5910ed00ec1489ce")
  .setClientSecret("c12516026334fb8dd0890090bfe2d25392e2ce2f7a8f177f")
  .setApiUri("http://localhost:8080/")
  .build().then( (cc) ->
    cc.configs().then((configs) ->
      console.log configs
      cc.config("test-qa", "test-prod").then( (config) ->
        console.log config
      )
    )
  )
