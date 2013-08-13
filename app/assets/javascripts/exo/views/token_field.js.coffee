namespace 'Exo.Views', (exports) ->
  class exports.TokenField extends Exo.View
    tagName: "div"
    maxTokens: Infinity
    placeholder: ""
    minInputValueLength: 2
    allowSubmit: true

    # Stupid idea?
    className: "token-field"
    selectedClassName: "selected"
    focusClassName: "focus"
    hasInputClassName: "has-input"
    inputClassName: "token-input"
    hiddenClass: "hidden"
    inputPlaceholderClassName: "input-placeholder"
    inputExpanderClassName: "input-expander"
    tokenSelectedClassName: "selected"
    tokenContainerClassName: "token-container"
    tokenClassName: "token-field-token"
    exceededLimitClassName: "exceeded-limit"

    itemDisplayAttributes: ["name", "title", "full_name", "email", "text", "query"]

    @TokenIndexes:
      All: -3
      Input: -2

    events:
      "blur input": "_blur"
      "focus input": "focus"
      "click": "_click"
      "click input": "_clickInput"
      "mousedown li:not(.token-input)": (e) ->
        e.preventDefault()
      "click li.token-field-token": "_clickToken"
      "click .close": "_clickTokenDelete"

    initialize: (options = {}) ->
      super

      if @originalInput = options.input
        @$originalInput = $(@originalInput)
        @$originalInput.wrap(@el)
        @$originalInput.attr("type", "hidden")
        @placeholderText = @$originalInput.attr("placeholder")
        @el = @$originalInput.parents()[0]
        @$el = $(@el)
        @delegateEvents()

      @selectedIndex = TokenField.TokenIndexes.Input
      @_collection = new Thorax.Collection
      @_collection.comparator = null

      @tokens = []

      @_collection.on "all", =>
        # Proxy collection events
        @trigger(arguments...)
        @_tokensChanged()

      @keyboardManager ||= new Exo.KeyboardManager(@el)

    render: ->
      # In case this is a re-render, remove the token-input
      $(@tokenInput).remove() if @tokenInput

      @tokenInput = document.createElement("li")
      @tokenInput.className = @inputClassName

      @input = document.createElement("input")
      @input.setAttribute("autocorrect", "off")
      @input.setAttribute("autocapitalize", "off")
      @input.setAttribute("autocomplete", "off")
      @input.setAttribute("tabindex", "0")

      @inputPlaceholder = document.createElement("span")
      @inputPlaceholder.className = @inputPlaceholderClassName

      # Text from @input is copied to this span to allow the
      # parent element to auto expand (native inputs don't support this)
      @inputExpander = document.createElement("span")
      @inputExpander.className = @inputExpanderClassName

      @_updatePlaceholder()

      @$input = $(@input)

      @_toggleInputVisibility()

      @tokenInput.appendChild(@input)
      @tokenInput.appendChild(@inputPlaceholder)
      @tokenInput.appendChild(@inputExpander)

      for token in @tokens
        @el.appendChild(token.element)

      @tokenContainer = document.createElement("ul")
      @tokenContainer.className = @tokenContainerClassName
      @tokenContainer.appendChild(@tokenInput)

      @el.appendChild(@tokenContainer)

      this

    insertToken: (tokens) ->
      return if @_maxTokensExceeded()

      tokens = if _.isArray(tokens) then tokens.slice() else [tokens]

      @render() if !@tokenInput

      for token in tokens
        token = @_buildToken(token)

        #unless @_collection.include(token.model)
        unless @_tokenExists(token.model)
          @tokenContainer.insertBefore(token.element, @tokenInput)
          @tokens.push token.element
          @_collection.add token.model

      @_updateInput()
      @_toggleInputVisibility()

    removeToken: (tokens, options) ->
      tokens = if _.isArray(tokens) then tokens.slice() else [tokens]

      for token in tokens
        index = @_collection.models.indexOf token
        if index != -1
          @deleteTokenAtIndex(index, true)

    # Clears any existing tokens and inserts passed in tokens
    setToken: (tokens) ->
      @deleteAll()
      @insertToken(tokens)

    selectPreviousToken: ->
      if @selectedIndex == 0
        return

      if @selectedIndex == TokenField.TokenIndexes.Input
        @selectTokenAtIndex(@_collection.length - 1)
      else
        @selectTokenAtIndex(@selectedIndex - 1)

    selectNextToken: ->
      if @selectedIndex == TokenField.TokenIndexes.Input
        return

      if @selectedIndex < @_collection.length - 1
        @selectTokenAtIndex(@selectedIndex + 1)
      else
        @selectTokenAtIndex(TokenField.TokenIndexes.Input)

    selectLastToken: ->
      @selectTokenAtIndex(@_collection.length - 1)

    selectTokenAtIndex: (index) ->
      @deselectAll()

      # TODO holy shit.. refactor this...
      if @selectedIndex != TokenField.TokenIndexes.Input && @selectedIndex != TokenField.TokenIndexes.All
        $(@tokens[@selectedIndex]).removeClass(@tokenSelectedClassName)

      if index == TokenField.TokenIndexes.Input
        @selectedIndex = TokenField.TokenIndexes.Input
        @$el.removeClass(@selectedClassName)
        return

      if index == TokenField.TokenIndexes.All
        @selectedIndex = TokenField.TokenIndexes.All
        @$el.find(".#{@tokenClassName}").addClass(@tokenSelectedClassName)
        @$el.addClass(@selectedClassName) if @input && @input.value.length == 0
        return

      if 0 <= index < @_collection.length
        @selectedIndex = index
        @$el.addClass(@selectedClassName) if @input && @input.value.length == 0
        $(@tokens[@selectedIndex]).addClass(@tokenSelectedClassName)

    selectTokenForObject: (object) ->
      for token, index in @_collection.models
        if token == object
          return @selectTokenAtIndex(index)

    deleteTokenAtIndex: (index, deselect) ->
      if index < @_collection.length
        token = @_collection.at(index)
        node = @tokens.splice(index, 1)[0]
        @tokenContainer.removeChild(node)
        @_collection.remove(token)
        if !deselect
          @selectedIndex = TokenField.TokenIndexes.Input
          if index >= @_collection.length
            @selectTokenAtIndex(TokenField.TokenIndexes.Input)
          else
            @selectTokenAtIndex(index)

        @_updateInput()
        @_toggleInputVisibility()

    deleteAll: ->
      @selectTokenAtIndex(TokenField.TokenIndexes.Input)
      $(@tokenContainer).children().remove(".#{@tokenClassName}")

      @_collection.reset()
      @tokens = []

      @_updateInput()
      @_toggleInputVisibility()

    deselectAll: ->
      @$el.find(@tokenSelectedClassName).removeClass(@tokenSelectedClassName)

    selectAll: ->
      @selectTokenAtIndex(TokenField.TokenIndexes.All)

    focus: (e) ->
      @$el.addClass(@focusClassName)

      @trigger("focus_LOL_THORAX_BUG", e)
      @keyboardManager.nominate this

    # Returns array of tags (strings or Backbone.models)
    #
    # @return [Array<String,Backbone.Model>] tags
    serialize: ->
      @_collection.models

    handleKeyUp: (key, e) ->
      @_updateInput(e)
      false

    handleKeyDown: (key, e) ->
      switch key
        when "backspace"
          if @selectedIndex == TokenField.TokenIndexes.All
            @deleteAll()
          else if @selectedIndex != TokenField.TokenIndexes.Input
            @deleteTokenAtIndex(@selectedIndex)
          else if @input.selectionStart == 0 && @input.selectionEnd == 0
            @selectTokenAtIndex(@_collection.length - 1)
        when "left"
          if @input.selectionStart == 0 || @selectedIndex != TokenField.TokenIndexes.Input
            e.preventDefault()
            @selectPreviousToken()
        when "right"
          if @selectedIndex != TokenField.TokenIndexes.Input
            e.preventDefault()
            @selectNextToken()
        when "⌘+A"
          if !@input.value.length
            @selectAll()
            e.preventDefault()
            return false
        when "enter"
          # Allow form submission if input is empty
          if !@input.value && @selectedIndex == TokenField.TokenIndexes.Input && @allowSubmit
            return true

          if @input.value
            @insertToken(@input.value)
            @$input?.val("")
            @input?.focus()

          e.preventDefault()
          e.stopPropagation()

          return false
        else
          if @selectedIndex != TokenField.TokenIndexes.Input
            @deleteTokenAtIndex(@selectedIndex, true)
            @selectedIndex = TokenField.TokenIndexes.Input
            @selectTokenAtIndex(TokenField.TokenIndexes.Input)

          @trigger("keypress", e)

      @_updateInput(e)
      undefined

    isFocused: ->
      @$el.hasClass(@focusClassName)

    destroy: ->
      @keyboardManager.revoke this
      @_collection.off(null, null, this)
      super

    #
    # Private
    #

    _getNodeIndex: (target) ->
      for token, index in @tokens
        if token.element == target
          return index
      return -1

    _queryMeetsMinLength: (query = @input.value) ->
      query.trim().length >= @minInputValueLength

    _maxTokensExceeded: ->
      @_collection.length >= @maxTokens

    # Events

    _clickToken: (e) ->
      @input.focus()

      e.stopPropagation()
      target = e.currentTarget

      if ((index = @_getNodeIndex(target)) >= 0)
        @selectTokenAtIndex(index)

    _clickTokenDelete: (e) ->
      e.stopPropagation()
      target = $(e.currentTarget).closest("li")[0]
      return if (index = @_getNodeIndex(target)) < 0

      @deleteTokenAtIndex(index, true)

      if @_collection.length == 0
        @selectedIndex = TokenField.TokenIndexes.Input
        @selectTokenAtIndex(TokenField.TokenIndexes.Input)
        @$input.focus()
        return

      if index <= @selectedIndex
        @selectedIndex = Math.max(index - 1, 0)
        @selectTokenAtIndex(@selectedIndex)

      return

    _updateInput: (e) ->
      return unless @input
      @inputExpander.textContent = @input.value || ""
      @$el.toggleClass(@hasInputClassName, (@input.value.length > 0))

    _blur: (e) ->
      @keyboardManager.revoke this

      @$el.removeClass(@focusClassName)
      @_updateInput(e)
      @selectTokenAtIndex(TokenField.TokenIndexes.Input)
      @trigger("blur_LOL_THORAX_BUG", e)

    _click: (e) ->
      @input.focus()
      @selectLastToken() if @_maxTokensExceeded()

    _clickInput: (e) ->
      @selectTokenAtIndex(TokenField.TokenIndexes.Input)

    # Other

    _updatePlaceholder: ->
      @inputPlaceholder?.innerHTML = @placeholderText

    _toggleInputVisibility: ->
      exceeded = @_maxTokensExceeded()
      $(@input).toggleClass(@hiddenClass, exceeded)
      @$el.toggleClass(@exceededLimitClassName, exceeded)

    _buildToken: (model) ->
      model = if model instanceof Backbone.Model then model else @_buildFallbackToken(model)

      { model: model, element: @_buildTokenNode(model) }

    # Refactor to template
    _buildTokenNode: (model) ->
      node = document.createElement("li")

      node.innerHTML = @_itemDisplayText(model)
      node.className = @tokenClassName
      node

    _tokensChanged: (token) ->
      @_updatePlaceholder() if @inputPlaceholder

    # Get the display text for a model by calling either `displayAttr` or by trying common display
    # text attributes
    _itemDisplayText: (item) ->
      displayText   = item.displayAttr?()

      for attr in ["name", "title", "full_name", "email", "text", "query"]
        displayText ||= item.get(attr)

      displayText

    _buildFallbackToken: (query) ->
      token = new Backbone.Model(query: query, _placeholder: true)
      token.displayAttr = ->
        @get("query")

      token

    _tokenExists: (model) ->
      if model.id
        @_collection.get(model)
      else
        @_collection.where(query: model.get("query")).length > 0
