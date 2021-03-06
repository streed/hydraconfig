window.ConfigModel = Backbone.Model.extend({
  idAttribute: 'name',
  url: function() {
    return '/api/config/' + this.id;
  }
});

window.ConfigCollection = Backbone.Collection.extend({
  model: ConfigModel,
  url: '/api/config'
});

window.ConfigModelValuesView = Backbone.View.extend({
  template: _.template($("#config-model-values-view").html()),
  valuesTemplate: _.template($("#config-model-values-value-view").html()),
  initialize: function(options) {
    this.values = options.values;
    this.config = options.config;
  },
  render: function() {
    var html = "";
    var self = this;
    _.each(this.values, function(v) {
      v.config = self.config;
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
    var config = this.model.id;
    var valueView = new window.ConfigModelValuesView({values: this.model.get("conf"), config: config});
    var values = valueView.render();
    console.log(values);
    var data = { "config": config, "values": values};
    var html = this.template(data);
    $(this.el).html(html);

    $("button[data-config='" + this.model.id + "']").click(function(e) {
      e.preventDefault();
      self.model.set({conf: _.reject(self.model.get("conf"), function(x) {
        return x.name == $(e.currentTarget).data("name");
      })});
      self.model.save();
    });

    $("#key-value-add").on( 'submit', function(e) {
      $(".error").empty();
      e.preventDefault();
      var key = $("#key").val();
      var value = $("#value").val();
      var model = self.model;

      var hash = _.reduce(model.get("conf"), function(h, v) {
        h[v.name] = v.value;
        return h
      }, {});

      hash[key] = value

      if(_.all(_.keys(hash), function(x) { return /^[a-z0-9]+(\.[a-z0-9]+)*$/i.test(x)})) {
        var conf = _.map(_.keys(hash), function(k) {
          return {name: k, value:hash[k]};
        });

        model.set("conf", conf); 
        model.save()
      } else {
        _.each(_.keys(hash), function(x) {
          if(!/^[a-z0-9]+(\.[a-z0-9]+)*$/i.test(x)) {
            $(".error").append("<div class='alert alert-danger'><p><strong>" + x + "</strong> - Must follow the following format: /^[a-z0-9]+(\\.[a-z0-9]+)*$/</p></div>");
          }
        });
      }
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
    this.model.on("save", function() {
      self.render();
    });
    var valueView = new window.ConfigModelValuesView({values: this.model.get("conf"), config: this.model.id});
    var config = this.model.id;
    var values = valueView.render()
    var data = { "config": config, "values": values};
    var html = this.template(data);
    $(this.el).append(html);
    $("button[data-config='" + this.model.id + "']").click(function(e) {
      e.preventDefault();
      self.model.set({conf: _.reject(self.model.get("conf"), function(x) {
        return x.name == $(e.currentTarget).data("name");
      })});
      self.model.save();
    });
  }
});
window.ConfigCollectionView = Backbone.View.extend({
  initialize: function(options) {
    this.el = options.el;
    this.collection = options.collection;
    this.collection.bind('add', this.render.bind(this));
    this.collection.bind('change', this.render.bind(this));
  },
  render: function() {
    $(this.el).empty();
    this.collection.forEach(this.renderOne.bind(this));
  },
  renderOne: function(c) {
    var view = new window.ConfigCollectionModelView({el: this.el, model: c});
    $(this.el).html(view.render());
  }
});
