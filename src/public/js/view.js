window.ConfigModel = Backbone.Model.extend({
  idAttribute: 'name',
  url: function() {
    return '/api/view/' + this.id;
  }
});

window.ConfigCollection = Backbone.Collection.extend({
  model: ConfigModel,
  url: '/api/view'
});

window.ConfigModelValuesView = Backbone.View.extend({
  template: _.template($("#config-model-values-view").html()),
  valuesTemplate: _.template($("#config-model-values-value-view").html()),
  initialize: function(options) {
    this.values = options.values;
  },
  render: function() {
    var html = "";
    var self = this;
    _.each(this.values, function(v) {
      html += self.valuesTemplate(v);
    });

    return this.template({name: this.name, values: html});
  }
})

window.ConfigModelView = Backbone.View.extend({
  template: _.template($("#config-model-view").html()),
  render: function() {
    var self = this;
    this.model.on('change', function() {
      self.render();
    });
    var valueView = new window.ConfigModelValuesView({values: this.model.get("conf")});
    var config = this.model.id;
    var values = valueView.render()
    var data = { "config": config, "values": values};
    var html = this.template(data);
    $(this.el).html(html);

    $("#key-value-add").on( 'submit', function(e) {
      e.preventDefault();
      var key = $("#key").val();
      var value = $("#value").val();
      var model = self.model;

      var hash = _.reduce(model.get("conf"), function(h, v) {
        h[v.name] = v.value;
        return h
      }, {});

      hash[key] = value

      var conf = _.map(_.keys(hash), function(k) {
        return {name: k, value:hash[k]};
      });

      model.set("conf", conf); 
      model.save();
    });
  }
});

window.ConfigCollectionModelView = Backbone.View.extend({
  template: _.template($("#config-collection-model-view").html()),
  render: function() {
    var self = this;
    this.model.on('change', function() {
      self.render();
    });
    var valueView = new window.ConfigModelValuesView({values: this.model.get("conf")});
    var config = this.model.id;
    var values = valueView.render()
    var data = { "config": config, "values": values};
    var html = this.template(data);
    $(this.el).append(html);
  }
});
window.ConfigCollectionView = Backbone.View.extend({
  initialize: function(options) {
    this.el = options.el;
    this.collection = options.collection;
    this.collection.bind('add', this.render.bind(this));
  },
  render: function() {
    this.el.empty();
    this.collection.forEach(this.renderOne.bind(this));
  },
  renderOne: function(c) {
    console.log(c); 
    var view = new window.ConfigCollectionModelView({el: this.el, model: c});
    this.el.append(view.render());
  }
});
