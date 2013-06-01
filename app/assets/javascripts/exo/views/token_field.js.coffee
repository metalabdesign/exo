namespace 'Exo.Views', (exports) ->
  class exports.TokenField extends Exo.View
    tagName: "div"
    className: "token-field"
    maxTokens: Infinity
    placeholder: ""
    minInputValueLength: 2
    itemTemplate: "token_field_token"

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
      @selectedIndex = TokenField.TokenIndexes.Input
      @tokens = new Exo.ArrayController()
      @tokens.comparator = null
      @properties = []
      @tokens.on("all", @_tokensChanged, this)
      @keyboardManager = new Exo.KeyboardManager

    render: ->
      # In case this is a re-render, remove the token-input
      $(@tokenInput).remove() if @tokenInput

      @tokenInput = document.createElement("li")
      @tokenInput.className = "token-input"

      @input = document.createElement("input")
      @input.setAttribute("autocorrect", "off")
      @input.setAttribute("autocapitalize", "off")
      @input.setAttribute("autocomplete", "off")
      @input.setAttribute("tabindex", "0")

      @inputPlaceholder = document.createElement("span")
      @inputPlaceholder.className = "input-placeholder"

      # Text from @input is copied to this span to allow the
      # parent element to auto expand (native inputs don't support this)
      @inputExpander = document.createElement("span")
      @inputExpander.className = "input-expander"

      @_setPlaceholder()

      @$input = $(@input)

      @_toggleInputVisibility()

      @tokenInput.appendChild(@input)
      @tokenInput.appendChild(@inputPlaceholder)
      @tokenInput.appendChild(@inputExpander)

      for property in @properties
        @el.appendChild(property.node)

      @tokenContainer = document.createElement("ul")
      @tokenContainer.className = "token-container"
      @tokenContainer.appendChild(@tokenInput)

      @el.appendChild(@tokenContainer)

      this

    insertToken: (strings, disableDelete = false) ->
      return if @maxTokensExceeded()

      strings = if _.isArray(strings) then strings.slice() else [strings]

      @render() if !@tokenInput

      for string in strings
        token = @_buildToken(string, disableDelete)

        unless @tokens.include(token.object)
          @tokenContainer.insertBefore(token.properties.node, @tokenInput)
          @properties.push token.properties
          @tokens.add token.object

      @selectLastToken() if @maxTokensExceeded()

      @_updateInput()
      @_toggleInputVisibility()

    removeToken: (tokens, options) ->
      tokens = if _.isArray(tokens) then tokens.slice() else [tokens]

      for token in tokens
        index = @tokens.array.indexOf token
        if index != -1
          @deleteTokenAtIndex index, true

    tokenize: (string) ->
      @insertToken(string)
      @input.value = ""

      if item == @input.value.slice(0, -1)
        item = @input.value

      if @maxTokens == 1 && @maxTokensExceeded()
        @deleteTokenAtIndex 0

    selectPreviousToken: ->
      if @selectedIndex == 0
        return

      if @selectedIndex == TokenField.TokenIndexes.Input
        @selectTokenAtIndex(@tokens.length - 1)
      else
        @selectTokenAtIndex(@selectedIndex - 1)

    selectNextToken: ->
      if @selectedIndex == TokenField.TokenIndexes.Input
        return

      if @selectedIndex < @tokens.length - 1
        @selectTokenAtIndex(@selectedIndex + 1)
      else
        @selectTokenAtIndex(TokenField.TokenIndexes.Input)

    selectLastToken: ->
      lastToken = @tokens.length - 1
      @selectTokenAtIndex(lastToken)

    selectTokenAtIndex: (index) ->
      @deselectAll()
      if @selectedIndex != TokenField.TokenIndexes.Input && @selectedIndex != TokenField.TokenIndexes.All
        $(@properties[@selectedIndex].node).removeClass("selected")

      if index == TokenField.TokenIndexes.Input
        @selectedIndex = TokenField.TokenIndexes.Input
        @$el.removeClass("selected-token")
        return

      if index == TokenField.TokenIndexes.All
        @selectedIndex = TokenField.TokenIndexes.All
        @$el.find(".token-field-token:not(.disable-delete)").addClass("selected")
        @$el.addClass("selected-token") if @input && @input.value.length == 0
        return

      if 0 <= index < @tokens.length
        return if @properties[index].disableDelete
        @selectedIndex = index
        @$el.addClass("selected-token") if @input && @input.value.length == 0
        $(@properties[@selectedIndex].node).addClass("selected")

    selectTokenForObject: (object) ->
      for token, index in @tokens.array
        if token == object
          return @selectTokenAtIndex(index)

    deleteTokenAtIndex: (index, deselect) ->
      if index == TokenField.TokenIndexes.All
        @deleteAll()
        @selectTokenAtIndex(TokenField.TokenIndexes.Input)
        return

      if index < @tokens.length
        return if @properties[index].disableDelete
        token = @tokens.at(index)
        node = @properties.splice(index, 1)[0].node
        @tokenContainer.removeChild(node)
        @tokens.remove(token)
        if !deselect
          @selectedIndex = TokenField.TokenIndexes.Input
          if index >= @tokens.length
            @selectTokenAtIndex(TokenField.TokenIndexes.Input)
          else
            @selectTokenAtIndex(index)

        @_updateInput()
        @_toggleInputVisibility()

    deleteAll: ->
      newProperties = []
      newTokens = []

      for item, index in @properties
        if item.disableDelete
          newProperties.push item
          newTokens.push @tokens.at(index)
        else
          @tokenContainer.removeChild(item.node)

      @tokens.reset(newTokens)
      @properties = newProperties

      @_updateInput()
      @_toggleInputVisibility()

    deselectAll: ->
      @$el.find(".selected").removeClass("selected")

    selectAll: ->
      @selectTokenAtIndex(TokenField.TokenIndexes.All)

    focus: (e) ->
      if @maxTokensExceeded()
        @selectTokenAtIndex(0)
      @_focusInput()
      @$el.addClass("focus")
      @trigger("focus", e)
      @keyboardManager.nominate this

    isFocused: ->
      @$el.hasClass("focus")

    maxTokensExceeded: ->
      @tokens.length >= @maxTokens

    destroy: ->
      @keyboardManager.revoke this
      @tokens.off(null, null, this)
      super

    #
    # Private
    #

    _focusInput: ->
      @input.focus()

    _getNodeIndex: (target) ->
      for item, index in @properties
        if item.node == target
          return index
      return -1

    # Events

    _clickToken: (e) ->
      e.stopPropagation()
      target = e.currentTarget

      if ((index = @_getNodeIndex(target)) >= 0)
        @selectTokenAtIndex(index)

      @_focusInput()

    _clickTokenDelete: (e) ->
      e.stopPropagation()
      target = $(e.currentTarget).closest("li")[0]
      return if (index = @_getNodeIndex(target)) < 0

      @deleteTokenAtIndex(index, true)

      if @tokens.length == 0
        @selectedIndex = TokenField.TokenIndexes.Input
        @selectTokenAtIndex(TokenField.TokenIndexes.Input)
        @$input.focus()
        return

      if index <= @selectedIndex
        @selectedIndex = Math.max(index - 1, 0)
        @selectTokenAtIndex(@selectedIndex)

      return

    handleKeyUp: (key, e) ->
      @_updateInput(e)
      false

    handleKeyDown: (key, e) ->
      isBackSpace = false
      switch key
        when "backspace"
          isBackSpace = true
          if @selectedIndex != TokenField.TokenIndexes.Input
            @deleteTokenAtIndex(@selectedIndex)
            e.preventDefault()
          else if @input.selectionStart == 0 && @input.selectionEnd == 0
            @selectTokenAtIndex(@tokens.length - 1)
            e.preventDefault()
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
          if !@input.value.length && @selectedIndex == TokenField.TokenIndexes.Input
            return true
          else if @input.value.length >= @minInputValueLength
            @tokenize(@input.value)
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

    _updateInput: (e) ->
      return unless @input
      @inputExpander.textContent = @input.value || ""
      @$el.toggleClass("has-input", (@input.value.length > 0))

    _blur: (e) ->
      @keyboardManager.revoke this

      @$el.removeClass("focus")
      @_updateInput(e)
      @selectTokenAtIndex(TokenField.TokenIndexes.Input)
      @trigger("blur", e)

    _click: (e) ->
      if @maxTokensExceeded()
        @selectTokenAtIndex(0)
      @_focusInput()

    _clickInput: (e) ->
      @selectTokenAtIndex(TokenField.TokenIndexes.Input)

    # Other

    _setPlaceholder: ->
      @inputPlaceholder?.innerHTML = @placeholder

    _toggleInputVisibility: ->
      exceeded = @maxTokensExceeded()
      $(@input).toggleClass("hidden", exceeded)
      @$el.toggleClass("exceeded-limit", exceeded)

    _buildToken: (object, disableDelete) ->
      node = document.createElement("li")
      node.innerHTML = object
      node.className = "token-field-token"

      properties = {node : node, disableDelete: disableDelete}
      token = {object: object, properties: properties}
      $(token.properties.node).addClass("disable-delete") if disableDelete

      return token

    _tokensChanged: (token) ->
      @_setPlaceholder() if @inputPlaceholder
