namespace 'Exo.Widgets.AutocompleteTokenField', (exports) ->

  # TODO add docs for all of these!!!

  exports.ReplaceIdStrategy = (tokens) ->
    if id = tokens[0]?.id
      @originalInput.value = id

  exports.ArrayStrategy = (tokens) ->
    inputName = @originalInput.name + "[]"
    @$el.find('[type="hidden"]').remove()

    for token in tokens
      input = document.createElement("input")
      input.name = inputName
      input.value = token.get("query")
      input.type = "hidden"
      @el.appendChild(input)
    return

  exports.NestedAttributesStrategy = (tokens) ->
    token = tokens[0]


    if !token.isNew()
      # If token is an existing object than convert nested attributes to ID attribute instead
      #
      # Example:
      #
      # employee[employer_attributes][name]
      #
      # becomes
      #
      # employee[employer_id]

      replaceNestedAttributesRegex = /_attributes](\[\w+\])+$/

      @originalInput.name = @originalInput.name.replace(replaceNestedAttributesRegex, "_id]")
      @originalInput.value = token.id
    else
      @originalInput.value = token.get("query")

  klass = class extends Exo.Views.AutocompleteTokenField
    constructor: (el, options = {}) ->
      @serializeStrategy = options.serializeStrategy || exports.ArrayStrategy

      options.input = el[0]
      super(options)

    initialize: (options) ->
      super

      @source ||= new Backbone.Collection
      @setSource(@source)

      unless @originalInput.value == ""
        @insertToken(@source.get(@originalInput.value))

      if options.tokens
        @setToken(options.tokens)

      @on "add remove", (token) =>
        @serializeStrategy.call(this, @serialize(), options)

  Exo.Widget.register("autoCompleteTokenField", klass)
