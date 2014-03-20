# Refactoring ideas:
# - Use a state machine
#
namespace 'Exo.Views', (exports) ->
  class exports.TokenField extends Exo.View
    tagName: "div"
    maxTokens: Infinity
    placeholder: ""
    minInputValueLength: 2
    allowSubmit: true

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
      "blur input": "blur"
      "focus input": "focus"
      "click": "_click"
      "mousedown": "_mouseDown"
      "click input": "_clickInput"
      "mousedown li:not(.token-input)": (e) ->
        e.preventDefault()
      "click li.token-field-token": "_clickToken"
      "click .close": "_clickTokenDelete"

    initialize: (options = {}) ->
      super

      @disabled ||= false

      if @originalInput = options.input
        @$originalInput = $(@originalInput)
        @$originalInput.wrap(@el)
        @$originalInput.attr("type", "hidden")
        @placeholder ||= @$originalInput.attr("placeholder")
        @setElement @$originalInput.parents()[0]

      @selectedIndex = TokenField.TokenIndexes.Input
      @_collection = new Thorax.Collection
      @_collection.comparator = null

      @tokens = []

      @_collection.on "all", =>
        # Proxy collection events
        @trigger(arguments...)
        @_tokensChanged()

      @keyboardManager ||= new Exo.KeyboardManager(@el)

      @render()

    render: ->
      return this if @_renderCount

      @input = document.createElement("input")
      @input.setAttribute("autocorrect", "off")
      @input.setAttribute("autocapitalize", "off")
      @input.setAttribute("autocomplete", "off")
      @input.setAttribute("tabindex", "0")

      @$input = $(@input)

      @$input.bind "paste", (e) =>
        _.defer => @handleKeyUp(e)

      @tokenInput = document.createElement("li")
      @tokenInput.className = @inputClassName

      @inputPlaceholder = document.createElement("span")
      @inputPlaceholder.className = @inputPlaceholderClassName

      # Text from @input is copied to this span to allow the
      # parent element to auto expand (native inputs don't support this)
      @inputExpander = document.createElement("span")
      @inputExpander.className = @inputExpanderClassName

      @tokenContainer = document.createElement("ul")
      @tokenContainer.className = @tokenContainerClassName

      @_updatePlaceholder()

      @_toggleInputVisibility()

      @tokenInput.appendChild(@input)
      @tokenInput.appendChild(@inputPlaceholder)
      @tokenInput.appendChild(@inputExpander)

      @tokenContainer.appendChild(@tokenInput)

      @el.appendChild(@tokenContainer)

      @_renderCount = 1
      @trigger("rendered")
      this

    insertToken: (tokens, options = {}) ->
      return if @_maxTokensExceeded()

      tokens = if _.isArray(tokens) then tokens.slice() else [tokens]

      @render() if !@tokenInput

      for token in tokens
        token = @_buildToken(token)

        unless @_tokenExists(token.model)
          @tokenContainer.insertBefore(token.element, @tokenInput)
          @tokens.push(token.element)
          @_collection.add(token.model, options)

      @_updateInput()
      @_toggleInputVisibility()

    removeToken: (tokens, options) ->
      tokens = if _.isArray(tokens) then tokens.slice() else [tokens]

      for token in tokens
        index = @_collection.models.indexOf token
        if index != -1
          @deleteTokenAtIndex(index, deselect: true)

    # Clears any existing tokens and inserts passed in tokens
    setTokens: (tokens, options = {}) ->
      @deleteAll(options)
      @insertToken(tokens, options)

    # Clears any existing tokens and inserts passed in tokens
    #
    # @depreciated in favour or setTokens
    setToken: (tokens, options = {}) ->
      @setTokens(tokens, options)

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

      @$input.addClass(@hiddenClass)

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

    deleteTokenAtIndex: (index, options = {}) ->
      if index < @_collection.length
        token = @_collection.at(index)
        node = @tokens.splice(index, 1)[0]
        @tokenContainer.removeChild(node)
        @_collection.remove(token, options)
        if !options.deselect
          @selectedIndex = TokenField.TokenIndexes.Input
          if index >= @_collection.length
            @selectTokenAtIndex(TokenField.TokenIndexes.Input)
          else
            @selectTokenAtIndex(index)

        @_updateInput()
        @_toggleInputVisibility()

    deleteAll: (options = {}) ->
      @selectTokenAtIndex(TokenField.TokenIndexes.Input)
      $(@tokenContainer).children().remove(".#{@tokenClassName}")

      @_collection.reset([], options)
      @tokens = []

      @_updateInput()
      @_toggleInputVisibility()

    deselectAll: ->
      @$el.find(@tokenSelectedClassName).removeClass(@tokenSelectedClassName)

    selectAll: ->
      @selectTokenAtIndex(TokenField.TokenIndexes.All)

    focus: (e) ->
      return if @isFocused() || @disabled

      @keyboardManager.nominate this
      @input.focus()
      @$el.addClass(@focusClassName)
      @$input.removeClass(@hiddenClass)
      @selectLastToken() if @_maxTokensExceeded()

      @trigger("focus_LOL_THORAX_BUG", e)

    blur: (e) ->
      return unless @isFocused()

      @keyboardManager.revoke this
      @$input.val("")
      @input.blur()
      @$el.removeClass(@focusClassName)
      @selectTokenAtIndex(TokenField.TokenIndexes.Input)
      @_updateInput(e)

      @trigger("blur_LOL_THORAX_BUG", e)

    disable: ->
      @disabled = true
      @$el.addClass("disabled")

    enable: ->
      @disabled = false
      @$el.removeClass("disabled")

    # Returns array of Backbone.models
    #
    # @return [Array<Backbone.Model>] tags
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
            @$input.val("")
            @focus()

          e.preventDefault()
          e.stopPropagation()

          return false
        when "tab", "⇧+tab"
          # Allow users to tab through token fields like any other input
          return false
        else
          @_keyPressed(e)

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
        if token == target
          return index
      return -1

    _queryMeetsMinLength: (query = @input.value) ->
      query.trim().length >= @minInputValueLength

    _maxTokensExceeded: ->
      @_collection.length >= @maxTokens

    _clickToken: (e) ->
      return if @disabled

      target = e.currentTarget
      index = @_getNodeIndex(target)

      @focus()
      @selectTokenAtIndex(index) if (index >= 0)

    _clickTokenDelete: (e) ->
      return if @disabled

      e.stopPropagation()
      target = $(e.currentTarget).closest("li")[0]

      # Wut?
      return if (index = @_getNodeIndex(target)) < 0

      @deleteTokenAtIndex(index, deselect: true)

      if @_collection.length == 0
        @selectedIndex = TokenField.TokenIndexes.Input
        @selectTokenAtIndex(TokenField.TokenIndexes.Input)
        @$input.focus()
        return

      if index <= @selectedIndex
        @selectedIndex = Math.max(index - 1, 0)
        @selectTokenAtIndex(@selectedIndex)

      return

    _click: (e) ->
      return if @disabled
      @focus()

    _clickInput: (e) ->
      return if @disabled || @selectedIndex == TokenField.TokenIndexes.Input
      @selectTokenAtIndex(TokenField.TokenIndexes.Input)

    _updateInput: (e) ->
      @inputExpander.textContent = @input.value || ""
      @$el.toggleClass(@hasInputClassName, (@input.value.length > 0))

    _mouseDown: (e) ->
      # Prevent input from blurring when token field wrapper is clicked
      e.stopPropagation()
      e.preventDefault()

    _keyPressed: (e) ->
      if @selectedIndex != TokenField.TokenIndexes.Input
        @deleteTokenAtIndex(@selectedIndex, deselect: true)
        @selectedIndex = TokenField.TokenIndexes.Input
        @selectTokenAtIndex(TokenField.TokenIndexes.Input)

      @$input.removeClass(@hiddenClass)

      @trigger("keypress", e)

    _updatePlaceholder: ->
      if @inputPlaceholder
        @inputPlaceholder.innerHTML = @placeholder

    _toggleInputVisibility: ->
      exceeded = @_maxTokensExceeded()
      @$input.toggleClass(@hiddenClass, exceeded)
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
      @_updatePlaceholder()

    # Get the display text for a model by calling either `displayAttr` or by trying common display
    # text attributes
    _itemDisplayText: (item) ->
      displayText = item.displayAttr?()

      for attr in ["name", "title", "full_name", "email", "text", "query"]
        displayText ||= item.get(attr)

      displayText

    _buildFallbackToken: (query) ->
      token = new Backbone.Model(query: query, _fallback: true)
      token.displayAttr = ->
        @get("query")

      token

    _tokenExists: (model) ->
      if model.id
        @_collection.get(model)
      else
        @_collection.where(query: model.get("query")).length > 0
