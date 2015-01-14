u.l.geo = {} # public API
# TODO v 0.8.3 does not provide the template in helper functions :(
# thus, collections need to be global, thus, only one area selector per page
collections = u.l.geo.collections =
  continents: new Meteor.Collection()
  countries: new Meteor.Collection()
  #states: new Meteor.Collection()
  cities: new Meteor.Collection()
Template.geoLocationSelector.created = ->
Template.geoLocationSelector.rendered = ->
  u.l.geo.areaController = @controller = new Controller @

class Controller
  geonames: u.l.geonames username: 'svub'
  collections: u.l.geo.collections
  #order: ['city', 'state', 'country']
  order: ['city', 'country']

  constructor: (@template) ->
    @root = @template.$ '.geo-location-selector'
    @root.data 'geoLocationSelectorController', @
    @loadCountries()
    findLocationMatch = (collection) ->
      logmr 'location match: current L', currentLocation = u.l.current true, true
      return unless currentLocation?
      # ip based: Germany, Europe
      # browser: 16, Hofreuthackerstraße, Unterbürg, Laufamholz, …,
      # Free State of Bavaria, 90482, Germany
      query =
        $or: (for element in currentLocation.label.split ', '
          label: $regex : element, $options : 'i')
      logmr 'location match', (collection.find query, sort: score: 1).fetch()[0]
    Deps.autorun => # get country that matches current location
      m = findLocationMatch @collections.countries
      if m? then Deps.afterFlush => @findSelect('country').val(m._id).change()
    Deps.autorun => # get city that matches current location
      m = findLocationMatch @collections.cities
      if m? then Deps.afterFlush => @findSelect('city').val(m._id)

  selected: ->
    logmr 'g.s.selected: distance', distance = u.parseIntOr (@root.find 'select.distance').val()
    for name in @order
      logr name, location = @findEntity @findSelect name
      if location?.lat?
        return logmr '...', _.extend {}, location,
          distance: (location.distance ? 0) + distance

  findSelect: (name) -> @root.find "select[name=#{name}]"
  findEntity: (select = @findSelect 'country') ->
    select = $ select; id = select.val()
    collection = switch select.attr 'name'
      when 'country' then @collections.countries
      when 'state' then @collections.states
      when 'city' then @collections.cities
    collection.findOne id

  loadCountries: ->
    @geonames.countryInfo (error, r) =>
      countries = u.l.geo.countries = r.geonames
      for continent in _.uniq _.pluck countries, 'continentName'
        @collections.continents.insert label: continent
      for country in countries
        @collections.countries.insert _.extend c = country,
          label: c.countryName
          lat: (c.north + c.south) / 2
          lng: (c.east + c.west) / 2
          distance: (u.l.distanceInMeters c.north, c.east, c.south, c.west) / 2
      logmr '<<<<<', @collections.countries.find().count()
      Deps.afterFlush =>
        @loadCities()

  loadCities: (country = @findEntity()) ->
    # searchJSON?country=GR&maxRows=10&cities=cities1000&username=svub
    @geonames.search country: country.countryCode, maxRows: 100, cities: 'cities1000', style: 'full', (error, r) =>
      logmr 'cities results', error, r
      cities = r.geonames
      @collections.cities.remove {}
      for city in cities
        bb = city.bbox
        @collections.cities.insert _.extend city,
          label: city.name
          distance: (u.l.distanceInMeters bb.north, bb.east, bb.south, bb.west) / 2


Template.geoLocationSelector.helpers
  test: -> [0,1]
  asdf: -> [{label:"aaa"},{label:"abc"}]
  countries: ->
    logr '>>>>>', @, arguments
    collections.countries.find {}, sort: countryName: 1
  states: -> collections.states.find()
  cities: -> collections.cities.find()
  groupedCountries: ->
    countries = (collections.countries.find {}, sort: countryName: 1).fetch()
    logmr 'grouped', (for group, values of _.groupBy countries, 'continentName'
      label: group
      values: values)
  groupedCities: ->
    cities = collections.cities.find().fetch()
    split = _.partition cities, (city) -> city.score >= 100
    [ { label: 'Major cities', values: split[0] },
      { label: 'Smaller cities', values: _.sortBy split[1], 'label' }]


Template.geoLocationSelector.events
  'change select[name=country]': (e,t) -> t.controller.loadCities()
  #'change select': (e,t) -> t.controller.setLastSelected e.target


Template.geoLocationSelectorOption.helpers
  label: -> @label ? @
  value: -> @_id ? @
