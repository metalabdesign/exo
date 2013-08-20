namespace 'Exo.Widgets.AutocompleteTokenField', (exports) ->

  exports.ReplaceIdStrategy = (tokens) ->
    if id = tokens[0].id
      @originalInput.value = id

  exports.ArrayStrategy = (tokens) ->
    inputName = @originalInput.name + "[]"
    @$el.find('[type="hidden"]').remove()
    for token in tokens
      input = document.createElement("input")
      input.name = inputName
      input.value = token
      input.type = "hidden"
      @el.appendChild(input)

  exports.NestedAttributesStrategy = (instance, tokens) ->

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

      if options.tokens
        @setToken(options.tokens)

      @on "change_LOL_THORAX_BUG", (tokens) =>
        @serializeStrategy.call(this, tokens)

  Exo.Widget.register("autoCompleteTokenField", klass)
