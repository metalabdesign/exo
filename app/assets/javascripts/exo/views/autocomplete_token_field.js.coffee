#= require ./token_field
#= require ./collection_list_popover
namespace 'Exo.Views', (exports) ->
  class exports.AutocompleteTokenField extends Exo.Views.TokenField
    resultsPopoverClass: Exo.Views.CollectionListPopover
    showPopoverOnEmpty: false
    minInputValueLength: 1
    allowNewTokens: true

    initialize: (options = {}) ->
      super

      @resultsPopover = options.resultsPopover || new @resultsPopoverClass(
        appendTo: @$el
        target: @$el
        tail: false
        keyboardManager: @keyboardManager
        position: {
          my: "left top"
          at: "left bottom"
          collision: "none"
        }
      )

      @resultsPopover.on("item:selected", @tokenize, this)

      @matcher = new Exo.Matcher

    setCollection: (collection, options = {}) ->
      super
      @matcher.addSource(@collection)

    tokenize: (token) ->
      if @allowNewTokens || @collection.get(token)
        super(token)

    handleKeyDown: (key, e) ->
      switch key
        when "enter"
          e.preventDefault()
          @_hideResultsPopover()
      super

    handleKeyUp: (key, e) ->
      switch key
        when "down"
          @_showResultsPopover() unless @resultsPopover.visible
        when "up", "down"
          # Prevent re-rendering when navigating auto-completer
          return false
        when "enter"
          e.preventDefault()
        else
          @_queryEntered(@input.value)
      super

    destroy: ->
      @resultsPopover.off null, null, this
      @resultsPopover = null
      super

    #
    # Private
    #

    _blur: (e) ->
      super
      @_hideResultsPopover()

    _shouldShowResultsPopover: (query) ->
      if @maxTokensExceeded()
        false
      else if @_queryMeetsMinLength(query)
        true
      else if @showPopoverOnEmpty && @input.value == ""
        true
      else
        false

    _queryEntered: (query) ->
      if @_shouldShowResultsPopover(query)
        @_showResultsPopover(query)
      else
        @_hideResultsPopover()

    _showResultsPopover: _.debounce((query) ->
      resultsCollection = new Thorax.Collection(@matcher.resultsForString(query).array)
      resultsCollection.remove(@tokens.array)

      resultsCollection.add({name: query})

      @resultsPopover.setCollection(resultsCollection)
      @resultsPopover.show()
    , 75)

    _hideResultsPopover: ->
      @resultsPopover.collection?.reset()
      @resultsPopover.hide()
