#= require ./token_field
#= require ./collection_list_popover
namespace 'Exo.Views', (exports) ->
  class exports.AutoCompleteTokenField extends Exo.Views.TokenField
    resultsPopoverClass: Exo.Views.CollectionListPopover
    showPopoverOnEmpty: true

    initialize: (options = {}) ->
      super

      @resultsPopover = options.resultsPopover || new @resultsPopoverClass(
        className: "auto-complete-results-popover popover"
        #appendTo: @el
      )
      @resultsPopover.on("item:selected", @tokenize, this)

      @matcher = new Exo.Matcher

    render: ->
      super
      @resultsPopover.setTarget(@input)

    setCollection: (collection, options = {}) ->
      super
      @matcher.addSource(@collection)

    tokenize: (item) ->
      # WTF does this do
      #if item == @input.value.slice(0, -1)
        #item = @input.value

      super

      @input.focus()
      #@resultsPopover.AutoCompleteTokenFieldItemSelected()

    handleKeyDown: (key, e) ->
      switch key
        when "backspace"
          @_queryEntered(@input.value)

      super

      #super

    handleKeyUp: (key, e) ->
      switch key
        when "up", "down"
          # Prevent re-rendering when navigating auto-completer
          return false

      @_queryEntered(@input.value)
      super

    #
    # Private
    #

    # Events

    _blur: (e) ->
      super
      @resultsPopover.hide()

    _queryMeetsMinLength: (query = @input.value) ->
      query.trim().length >= @minInputValueLength

    _queryEntered: (query) ->
      @_showPopover(query) if @_queryMeetsMinLength(query)

    # Other

    _showPopover: _.debounce((query) ->
      return if @maxTokensExceeded()
      return if @input.value == ""
      @resultsPopover.setCollection(@matcher.resultsForString(query))
      @resultsPopover.show()
    , 75)

    destroy: ->
      @resultsPopover.off null, null, this
      @resultsPopover = null
      super

