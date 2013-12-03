#= require ./token_field
#= require ./collection_list_popover
namespace 'Exo.Views', (exports) ->
  class exports.AutocompleteTokenField extends Exo.Views.TokenField
    resultsPopoverClass: Exo.Views.CollectionListPopover
    showPopoverOnEmpty: false
    minInputValueLength: 1
    allowFallbackTokens: true
    showAllOnDownArrow: false

    initialize: (options = {}) ->
      super

      @resultsPopover = options.resultsPopover || new @resultsPopoverClass(
        appendTo: @$el
        target: @$el
        tail: false
        setupEvents: false
        keyboardManager: @keyboardManager
        position: {
          my: "left top"
          at: "left bottom"
          collision: "none"
        }
      )

      @resultsPopover.itemContext = (model) =>
        _.extend {
          displayAttr: @_itemDisplayText(model)
        }, model.attributes

      # Attribute to filter models by
      @filterAttribute = options.filterAttribute || "name"

      @resultsPopover.on "item:selected", (model) ->
        model = if _.isString(model) then @_buildFallbackToken(model) else model
        @insertToken(model)
        @$input?.val("")
      , this

      @matcher = new Exo.Matcher
        filterAttribute: @filterAttribute

    setSource: (source) ->
      @matcher.setSource(source)

    addSource: (source) ->
      @matcher.addSource(source)

    handleKeyUp: (key, e) ->
      switch key
        when "up"
          return false # Prevent re-rendering when navigating auto-completer
        when "down"
          # Buggy..
          if @showAllOnDownArrow && @input.value == "" && !@resultsPopover.visible
            @_showResultsPopover()
          else
            return false
        else
          @_queryEntered(@input.value)

      super

    handleKeyDown: (key, e) ->
      switch key
        when "tab", "⇧+tab"
          @_hideResultsPopover()
        when "up", "down"
          return false # Prevent re-rendering when navigating auto-completer
        when "enter"
          if @selectedIndex > -1
            # Don't add tokens on 'enter', this happens by watching for
            # `item:selected` events on @resultsPopover instead
            e.preventDefault()
            e.stopPropagation()
            return false

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
      if @_maxTokensExceeded()
        false
      else if @_queryMeetsMinLength(query)
        true
      else
        false

    _queryEntered: (query) ->
      if @_shouldShowResultsPopover(query)
        @_showResultsPopover(query)
      else
        @_hideResultsPopover()

    _showResultsPopover: _.debounce((query) ->
      @matcher.resultsForString query, (results) =>
        resultsCollection = new Thorax.Collection(results.array)

        # Don't show tokens in the results collection that already exist in the token field
        resultsCollection.remove(@_collection.models)

        if @allowFallbackTokens
          # Insert a 'fallback' token for the currently entered query which the user can select
          # if they wish to create a new item rather than using an exsting one
          resultsCollection.add(@_buildFallbackToken(query))

        @resultsPopover.setCollection(resultsCollection)
        @resultsPopover.selectAtIndex(0)
        @resultsPopover.show()
    , 25)

    _hideResultsPopover: ->
      @resultsPopover.collection?.reset()
      @resultsPopover.hide()
