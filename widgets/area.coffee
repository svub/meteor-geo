Template.geoArea.rendered = ->
  root = @$ '.geo-area'
  root.data 'controller', @controller = new GeoAreaController root, @, @data

Template.geoArea.helpers
  myLocation: -> u.l.current()?.label

Template.geoArea.events
  'click .current-location': -> u.l.current true

class GeoAreaController
  constructor: (@root, @template, @config) ->
    #check @config, Object
    #check @config.session, String
    @selectorController = (@root.find '.geo-location-selector').data 'geoLocationSelectorController'

  setArea: (area) -> Session.set @config.session, area
  selected: ->
    location = source: (@root.find '.tab-pane.active').attr 'id'
    switch location.source
      when 'aroundme' then _.extend location, u.l.current(),
        distance: (@root.find '#aroundme select.distance').val()
      #when 'area' then _.extend location, @lastAreaSelected
      when 'area' then _.extend location, @selectorController.selected()
      else null # anywhere

