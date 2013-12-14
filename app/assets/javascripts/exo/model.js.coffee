namespace 'Exo', (exports) ->
  class exports.Model extends Thorax.Model

    # A map of attributes to classes that are automatically transformed into
    # their respective classess. Expects class to be either a Model or Collection
    # and will be passed the value of the attribute as the first arg to its
    # constructor.
    embeddedResources: null

    initialize: ->
      super

      # ensure we always have an instance we can reference for our nested models
      for attr, klass of (@embeddedResources || [])
        @attributes[attr] = new klass() if !@attributes[attr]

    # Our nested models will trick the default implementation of isPopulated
    # to return true. We don't want that.
    isPopulated: ->
      attributes = _.clone @attributes
      defaults = _.result(this, 'defaults') || {}

      for default_key of defaults
        return true if attributes[default_key] != defaults[default_key]
        delete attributes[default_key]

      for nested_attr, klass of (@embeddedResources || [])
        delete attributes[nested_attr]

      keys = _.keys attributes
      return keys.length > 1 || (keys.length == 1 && keys[0] != 'id')

    # Override default Thorax load to accept an options hash w/ callbacks
    # instead of load(callback, failback, options)
    load: (options = {}) ->
      if _.isFunction options
        callback = options
        options = {}
      else
        callback = options.success || (->)
        failback = options.error || (->)

      super(callback, failback, options)

    set: (key, val, options) ->
      return this if key == null

      # Handle both `"key", value` and `{key: value}` -style arguments.
      if _.isObject(key)
        attrs = key
        options = val
      else
        (attrs = {})[key] = val

      # Intercept `set` calls to a registerd nested model, and call reset on
      # it instead
      for attr, klass of (@embeddedResources || [])
        if attrs[attr] && @attributes[attr] instanceof klass
          data = attrs[attr]

          if @attributes[attr] instanceof Backbone.Collection
            data = data.models if data instanceof Backbone.Collection
            @attributes[attr].reset(data, options)
            delete attrs[attr]
          else
            if data instanceof Backbone.Model && data.id == @attributes[attr].id
              data = data.attributes
              @attributes[attr].set(data, options)
              delete attrs[attr]
            else
              # noop if we're setting a new model completely. Let super
              # fire change:attr like normal

      super(attrs, options)

    parse: (resp) ->
      if resp # PATCH requests return an empty response
        for attr, klass of (@embeddedResources || [])
          data = resp[attr]
          resp[attr] = new klass(data, parse: true)

      super(resp)
