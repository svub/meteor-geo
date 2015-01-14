u.l ?= {}
_.extend u.l,
  geonames: (params) ->
    check params, Object
    check un = params.username, String
    params.locale ?= language: 'en', country : 'US'
    if Meteor.isServer
      Geode = Npm.require 'geode'
      new Geode un, params.locale
    else new GeonamesClient params
  _currentLoading: browser: false, ip: false
  current: (load = false, viaBrowser = false, callback) ->
    type = (viaBrowser) -> if viaBrowser then 'browser' else 'ip'
    name = (viaBrowser) -> "geo_location-info_#{type viaBrowser}"
    get = (viaBrowser) -> Session.get name viaBrowser
    # got match geo location already?
    if (l = get true)? then return l
    # TODO fall back to IP based if browser location failed
    if viaBrowser is false and (l = get false)? then return l

    if load and not u.l._currentLoading[type viaBrowser]
      u.l._currentLoading[type viaBrowser] = true
      # TODO move method here
      u.x.currentLocation viaBrowser, (location) ->
        u.l._currentLoading[type viaBrowser] = false
        if location is false then location = null
        Session.set (name viaBrowser), location
    null

later -> u.l.current true, false # preload IP location

class GeonamesClient
  constructor: (@params) ->
    @endpoint = 'http://api.geonames.org/'
    @username = params.username
    for method in @methods
      do (method) =>
        @[method] ?= (data, callback = u.cb) =>
          if _.isFunction data then [data, callback] = [null, data]
          @request method, data, callback

  request: (method, data, callback) ->
    logr url = @endpoint + method + 'JSON'
    logr payload = _.extend {}, @params, data
    $.ajax
      dataType: 'json'
      url : url
      data : payload
      success: (data, status, jqXHR) -> callback null, data
      error: (jqXHR, status, error) -> callback error: error, status: status

  methods: [
    'search',
    'get',
    'postalCode',
    'postalCodeLookup',
    'findNearbyPostalCodes',
    'postalCodeCountryInfo',
    'findNearbyPlaceName',
    'findNearby',
    'extendedFindNearby',
    'children',
    'hierarchy',
    'neighbours',
    'siblings',
    'findNearbyWikipedia',
    'wikipediaSearch',
    'wikipediaBoundingBox',
    'cities',
    'earthquakes',
    'weather',
    'weatherIcaoJSON',
    'findNearByWeather',
    'countryInfo',
    'countryCode',
    'countrySubdivision',
    'ocean',
    'neighbourhood',
    'srtm3',
    'astergdem',
    'gtopo30',
    'timezone'
  ]

