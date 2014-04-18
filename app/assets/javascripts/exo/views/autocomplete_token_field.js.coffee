#= require ./token_field
#= require ./collection_list_popover

namespace 'Exo.Views', (exports) ->
  class exports.AutocompleteTokenField extends Exo.Views.TokenField

    minInputValueLength: 1

    # Allow tokens for queries not in the collection
    allowFallbackTokens: true
    showAllOnDownArrow: false

    # Attribute on models to search.
    filterAttribute: 'name'

    # Results popover
    resultsPopoverClass: Exo.Views.CollectionListPopover
    resultsPopoverOptions: null
    showPopoverOnEmpty: false


    #-----------------------------------------------------------------------------
    # Constructor
    #-----------------------------------------------------------------------------

    initialize: ->
      super

      @resultsPopover ?= new @resultsPopoverClass(
        _.extend({
          appendTo: @$el
          target: @$el
          tail: false
          setupEvents: false
          keyboardManager: @keyboardManager
          position:
            my: 'left top'
            at: 'left bottom'
            collision: 'none'
        }, @resultsPopoverOptions)
      )

      @resultsPopover.itemContext = (model) =>
        _.extend {
          displayAttr: @_itemDisplayText(model)
        }, model.attributes

      @resultsPopover.on 'item:selected', (model) ->
        model = if _.isString(model) then @_buildFallbackToken(model) else model
        @insertToken(model)
        @$input?.val('')
      , this

      @matcher = new Exo.Matcher
        filterAttribute: @filterAttribute

      @on 'destroyed', @_destroyed

      this


    #-----------------------------------------------------------------------------
    # Instance Methods
    #-----------------------------------------------------------------------------

    setSource: (source) ->
      @matcher.setSource(source)

    addSource: (source) ->
      @matcher.addSource(source)


    #-----------------------------------------------------------------------------
    # Delegate Methods
    #-----------------------------------------------------------------------------

    handleKeyUp: (key, e) ->
      switch key
        when 'up'
          return false # Prevent re-rendering when navigating auto-completer
        when 'down'
          # Buggy..
          if @showAllOnDownArrow && @input.value == '' && !@resultsPopover.visible
            @_showResultsPopover()
          else
            return false
        else
          @_queryEntered(@input.value)
          @inputPlaceholder.style.display = if @_shouldShowPlaceholder() then '' else 'none'

      super

    handleKeyDown: (key, e) ->
      switch key
        when 'tab', '⇧+tab'
          @_hideResultsPopover()
        when 'up', 'down'
          return false # Prevent re-rendering when navigating auto-completer
        when 'enter'
          if @selectedIndex > -1
            # Don't add tokens on 'enter', this happens by watching for
            # `item:selected` events on @resultsPopover instead
            e.preventDefault()
            e.stopPropagation()
            return false

      super


    #-----------------------------------------------------------------------------
    # Private Methods
    #-----------------------------------------------------------------------------

    # @returns {boolean}
    _shouldShowResultsPopover: (query) ->
      !@_maxTokensExceeded() && @_queryMeetsMinLength(query)

    # @returns {boolean}
    _shouldAddFallbackToken: (model, results) ->
      !@_tokenExists(model) && !(results[0]?.score == 1.0)

    # @returns {boolean}
    _shouldShowPlaceholder: (event) ->
      !@_collection.length && !@input.value.trim()

    #-----------------------------------------------------------------------------
    # Event Handlers
    #-----------------------------------------------------------------------------

    _blur: (event) ->
      super
      @_hideResultsPopover()

    _destroyed: =>
      @resultsPopover.off(null, null, this)
      @resultsPopover = null

    _queryEntered: (query) ->
      if @_shouldShowResultsPopover(query)
        @_showResultsPopover(query)
      else
        @_hideResultsPopover()

    _showResultsPopover: _.debounce((query) ->
      @matcher.resultsForString query, (results) =>
        models = _.pluck(results, 'model')
        collection = new Thorax.Collection(models)

        # Don't show tokens in the results collection that already exist in the token field
        collection.remove(@_collection.models)

        if @allowFallbackTokens
          # Insert a 'fallback' token for the currently entered query which the user can select
          # if they wish to create a new item rather than using an exsting one
          fallbackModel = @_buildFallbackToken(query)
          collection.add(fallbackModel) if @_shouldAddFallbackToken(fallbackModel, results)

        @resultsPopover.setCollection(collection)
        @resultsPopover.selectAtIndex(0)
        @resultsPopover.show()
    , 25)

    _hideResultsPopover: ->
      @resultsPopover.collection?.reset()
      @resultsPopover.hide()
