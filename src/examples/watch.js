request = require("request");

clientId = "8a1143fe5910ed00ec1489ce";
clientSecret = "c12516026334fb8dd0890090bfe2d25392e2ce2f7a8f177f"

data = {
  "grant_type": "client_credentials",
  "client_id": clientId,
  "client_secret": clientSecret
};

request.post("http://localhost:8080/oauth/token", {form: data}, function(err, response, body) {
  accessToken = JSON.parse(body).access_token
  request.get({ url: "http://localhost:8080/api/watch/test", headers: { "Authorization": "Bearer " + accessToken } }, function( err, response, body) {
    console.log(JSON.stringify(JSON.parse(body), null, 2));
  });
})
