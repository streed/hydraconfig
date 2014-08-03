window.StateModel = Backbone.Model.extend({
  url: '/api/state'
});

window.StateModelView = Backbone.View.extend({
  template: _.template($("#state-model-view").html()),
  render: function() {
    $(this.el).html(this.template({state: this.model.attributes}));
  }
});
