window.UserModel = Backbone.Model.extend({
  url: '/oauth/token'
});
window.userAuth = function(email, password) {
  var defer = Q.defer();

  var userModel = new window.UserModel({email:email, password:password, grant_type:"password"});

  Backbone.emulateJSON = true

  userModel.save({email: email, password: password}, {success: function(auth) {
    defer.resolve(auth.access_token);
  }});

  return defer.promise;
}

