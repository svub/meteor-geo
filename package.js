Package.describe({
  summary: "Provides open source only geocoding, reverse geocoding and UI widgets based on Open Street Maps, Geonames, and Leaflet."
});

Package.on_use(function (api, where) {
  Npm.depends({geode: '0.0.6'});

  common = ['client', 'server'];
  api.use(['underscore', 'coffeescript', 'underscore-string-latest', 'meteor', 'ejson', 'mongo-livedata', 'deps', 'check'], common);
  api.use(['minimongo', 'less', 'templating', 'session', 'jquery'], 'client');

  api.add_files('geo.coffee', 'client');

  addWidget = function(name) { // I want package.coffee!!
    endings = ['html', 'less', 'coffee'];
    for (var x = 0; x < 3; x++)
      api.add_files('widgets/'+name+'.'+endings[x], 'client');
  }
  addWidget('selector');
  addWidget('area');

});
