namespace 'Exo.Widgets.AutocompleteTokenField', (exports) ->

  hiddenFieldNamePrefix = (originalInput) ->
    #originalInput.attr("name").replace(/\[\w+\]$/, "[#{attr}]")
    
  exports.ReplaceIdStrategy = (tokens) ->
    if id = tokens[0].id
      @originalInput.value = id

  exports.ArrayStrategy = (instance, tokens) ->
  exports.NestedAttributesStrategy = (instance, tokens) ->
    # WIP
    #prefix = hiddenFieldNamePrefix(instance.originalInput)

    ##instance.$el.find(

    #for token, index in tokens
      #if instance instanceof Backbone.Model && instance.id
        #value = token.id
      #else
        #value = token

      #instance.$el.append("<input type=\"hidden\" name=\"#{name}\" value=\"#{value}\"/>")

  
  klass = class extends Exo.Views.AutocompleteTokenField

    constructor: (el, options = {}) ->
      @serializeStrategy = options.serializeStrategy || exports.NestedAttributesStrategy
      options.input = el[0]
      super(options)

    initialize: (options) ->
      super

      @render()

      unless @originalInput.value == ""
        @insertToken(@collection.get(@originalInput.value))

      @on "change_LOL_THORAX_BUG", (tokens) =>
        @serializeStrategy.call(this, tokens)

  Exo.Widget.register("autoCompleteTokenField", klass)
