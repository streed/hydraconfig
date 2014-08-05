request = require("request");

clientId = "48ca25eee4f060ebf0689d52";
clientSecret = "f298e2a94ccb72d95e8be875f5c55e518b848eaddd8d3dbc"

data = {
  "grant_type": "client_credentials",
  "client_id": clientId,
  "client_secret": clientSecret
};

request.post("http://localhost:8080/oauth/token", {form: data}, function(err, response, body) {
  console.log( body );

  refresh = JSON.parse(body).refresh_token
  data = { 
    "grant_type": "refresh_token",
    "client_id": clientId,
    "client_secret": clientSecret,
    "refresh_token": refresh
  }

  request.post("http://localhost:8080/oauth/token", {form: data}, function(err, response, body) {
    console.log(body);
  })
})
