class @Exo.Widget

  delegateEventSplitter = /^(\S+)\s*(.*)$/

  _.extend(@prototype, Backbone.Events) if Backbone?.Events

  @register: (name, klass) ->
    $.fn[name] = (options = {}) ->
      (new klass(element, options) for element in this)
      return # No need to collect results

  constructor: (el, options) ->
    @cid = _.uniqueId "exo-widget"
    @setElement(el)

    @options = {}
    dataOptions = {}
    sanitizer = new RegExp("^#{ @constructor.name.toLowerCase() }(\\w+)")
    for key, value of @el.dataset
      if match = key.match(sanitizer)
        realKey = match[1]
        realKey = realKey[0].toLowerCase() + realKey.substr(1)
        dataOptions[realKey] = value

    @setOptions dataOptions, @defaults, options

  setOptions: (options...) ->
    @options = _.extend.apply null, [@options].concat options

  setElement: (element, delegate) ->
    @undelegateEvents() if @$el
    @$el = if element instanceof $ then element else $(element)
    @el = @$el[0]
    @delegateEvents() if delegate != false
    this

  delegateEvents: (events) ->
    @undelegateEvents()
    @_delegateEvents(@constructor.events)
    @_delegateEvents(events || @events)
    this

  _delegateEvents: (events) ->
    for key, method of events
      method = this[method] if !_.isFunction(method)
      throw new Error("Method '#{ events[key] }' does not exist") if !method
      match = key.match(delegateEventSplitter)
      eventName = match[1]
      selector = match[2]
      method = _.bind(method, this)
      eventName += ".delegateEvents-#{ @cid }"

      if selector == ""
        @$el.on(eventName, method)
      else
        @$el.on(eventName, selector, method)

    this

  undelegateEvents: ->
    @$el.off(".delegateEvents-#{ @cid }")
    this
