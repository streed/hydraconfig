request = require("request");

clientId = "3ae781a47397e6d6df64b677";
clientSecret = "88eb5df16899da110952d98462fef1f0d816c0d75427b599"

data = {
  "grant_type": "client_credentials",
  "client_id": clientId,
  "client_secret": clientSecret
};

request.post("http://elt.li/oauth/token", {form: data}, function(err, response, body) {
  accessToken = JSON.parse(body).access_token
  request.get({ url: "http://elt.li/api/config", headers: { "Authorization": "Bearer " + accessToken } }, function( err, response, body) {
    console.log(JSON.stringify(JSON.parse(body), null, 2));
  });
})
