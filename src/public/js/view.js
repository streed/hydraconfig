window.ApiKeyModel = Backbone.Model.extend({
  url: function() {
    return '/api/key/' + this.id;
  }
});

window.ApiKeyCollection = Backbone.Collection.extend({
  model: ApiKeyModel,
  url: function() {
    return '/api/key/' + this.userId
  }
});

window.ApiKeyCollectionModelView = Backbone.View.extend({
  template: _.template($("#apiKey-model-view").html()),
  render: function() {
    var apiKey = this.model.id;
    var data = {apiKey: apiKey, clientId: this.model.get("clientId"), clientSecret: this.model.get("clientSecret")};
    var html = this.template(data);
    $(this.el).append(html);
  }
});
window.ApiKeyCollectionView = Backbone.View.extend({
  initialize: function(options) {
    this.el = options.el;
    this.collection = options.collection;
    this.collection.bind('add', this.render.bind(this));
    this.collection.bind('change', this.render.bind(this));
    var self = this;
    $(".generate-key").click(function(e) {
      e.preventDefault()
      fake = new window.ApiKeyModel();
      fake.save({userId: options.userId, id: "new"}, {
        success: function() {
          self.collection.fetch();
        }
      });
    });
  },
  render: function() {
    $(this.el).empty();
    this.collection.forEach(this.renderOne.bind(this));
  },
  renderOne: function(c) {
    var view = new window.ApiKeyCollectionModelView({el: this.el, model: c});
    $(this.el).html(view.render());
  }
});
