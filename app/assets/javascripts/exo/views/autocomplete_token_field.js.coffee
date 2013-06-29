#= require ./token_field
#= require ./collection_list_popover
namespace 'Exo.Views', (exports) ->
  class exports.AutocompleteTokenField extends Exo.Views.TokenField
    resultsPopoverClass: Exo.Views.CollectionListPopover
    showPopoverOnEmpty: false
    minInputValueLength: 1
    allowNewTokens: true
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

      # Attribute to filter models by
      @filterAttribute = options.filterAttribute || "name"

      @resultsPopover.on "item:selected", (model) ->
        # If the model is a placeholder then tokenize just its name so that a new item is created
        # instead of using an existing one
        if model.get("_new")
          @tokenize(model.get("name"))
        else
          @tokenize(model)
      , this

      @matcher = new Exo.Matcher

    setCollection: (collection, options = {}) ->
      super
      @matcher.addSource(@collection)

    tokenize: (token) ->
      if @allowNewTokens || @collection.get(token)
        super(token)

    handleKeyUp: (key, e) ->
      switch key
        when "down"
          if @showAllOnDownArrow && @input.value == "" && !@resultsPopover.visible
            @_showResultsPopover()
        when "up", "down"
          # Prevent re-rendering when navigating auto-completer
          return false
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
      if @_maxTokensExceeded()
        false
      else if @_queryMeetsMinLength(query)
        true
      else if @showAllOnDownArrow && @input.value == ""
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

      if @allowNewTokens
        # Insert a placeholder token for the currently entered query which the user can select
        # if they wish to create a new item rather than using an exsting one
        resultsCollection.add({name: query, _new: true}) 

      @resultsPopover.setCollection(resultsCollection)
      @resultsPopover.show()
    , 75)

    _hideResultsPopover: ->
      @resultsPopover.collection?.reset()
      @resultsPopover.hide()

    _itemDisplayText: (item) ->
      if item instanceof Backbone.Model
        displayText = item.get(@modelFilterAttr)
        (-> displayText ||= item.get(attr))() for attr in ["name", "title", "full_name", "email"]
        displayText
      else
        super

