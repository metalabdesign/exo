#= require ./token_field
namespace "Flow.Views", (exports) ->

  # Token field that can be passed a collection (or ArrayController) of models
  # to autocomplete against

  class exports.AutoCompleteTokenField extends exports.TokenField

    # Token types that may only exist one at a time in the token field
    exclusiveTokenTypes: [Flow.Models.List, Flow.Models.Group]
    showStringItem: true

    initialize: (options = {}) ->
      super

      @resultsView = options.resultsView || @view "AutoCompleteResultsPopover", options.resultsViewOptions
      @resultsView.delegate = this
      @resultsView.on("item:selected", @tokenize, this)

      tokenTemplates =
        list: (obj) ->
          return unless obj instanceof Flow.Models.List
          @template("#{@name}_list_item", {name: obj.get("name")})

        group: (obj) ->
          return unless obj instanceof Flow.Models.Group
          @template("#{@name}_group_item", {name: obj.get("name")})

        account: (obj) ->
          return unless obj instanceof Flow.Models.Account
          context = {
            "name": obj.get("first_name")
            "model-cid": obj.cid # For avatar in template
          }
          @template("#{@name}_account_item", context)

        tag: (obj) ->
          return unless obj instanceof Flow.Models.Tag
          @template("#{@name}_tag_item", {name: obj.name})

      @tokenTemplates = _.extend @tokenTemplates, tokenTemplates

    render: ->
      super
      @resultsView.setTarget?(@input)

    setCollection: (@collection, options = {}) ->
      @resultsView.setCollection collection
      this

    getCollection: ->
      @resultsView.originalCollection

    tokenize: (item) ->
      if item == @input.value.slice(0, -1)
        item = @input.value

      if @maxTokens == 1 && @maxTokensExceeded()
        @deleteTokenAtIndex 0
      super
      @input.focus()
      @resultsView.AutoCompleteTokenFieldItemSelected()

    queryMeetsMinLength: (query = @input.value) ->
      query.trim().length >= @minInputValueLength

    handleKeyDown: (key, e) ->
      switch key
        when "backspace"
          query = Flow.Helpers.EstimateInputValue(@input.value, e, {
            target: @input
            multipleLines: false
          })
          @_queryEntered(query)

      super

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

    _keypress: (e) ->
      key = Flow.Helpers.keyNameForCode(e.keyCode)
      if key == "enter" && @input.value == ""
        @_submit()
        e.preventDefault()
        return

      super

    _submit: ->
      @trigger("submit")

    _blur: (e) ->
      super
      @resultsView.AutoCompleteTokenFieldBlur()

    _queryEntered: (query) ->
      if @queryMeetsMinLength(query)
        @_showPopover(query)
      else
        @resultsView.AutoCompleteTokenFieldEmpty(false)

    # Other

    _showPopover: _.debounce((query) ->
      return if @maxTokensExceeded()
      return if @input.value == ""
      @resultsView._filterCollection query
      @resultsView.AutoCompleteTokenFieldResults()
    , 75)

    # Perform various filtering on the query results for the autocompleter
    # - Filter out items that are already represented in the token field
    # - Filter out exclusive token types that are already represented in the token field
    PreprocessFilteredData: (collection, query, resultsView) ->
      results = new ArrayController()
      results.comparator = null

      # A list of any exclusive token types that already exist in the token field
      existingExclusiveTokenTypes = _.reduce(@exclusiveTokenTypes, (list, tokenType) =>
        typeExists = @tokens.detect((object) -> (object instanceof tokenType))
        list.push(tokenType) if typeExists
        list
      , [])


      collection.each (item) =>

        # Return if this item is already exists in the token field
        isDuplicate = @tokens.detect((token) ->
          token.cid == item.cid if token.cid
        )

        if isDuplicate
          return

        # Return if this item matches an existing exclusive token type
        unless @maxTokens == 1
          for tokenType in existingExclusiveTokenTypes
            return if (item instanceof tokenType)

        # If none of the above filters matched, add the result
        results.add item

      # Add search item if search is enabled
      results.add(query) if query && @showStringItem
      results

    destroy: ->
      @resultsView.off null, null, this
      @resultsView = null
      super

