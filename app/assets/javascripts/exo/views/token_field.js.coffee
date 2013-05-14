class @Exo.Views.TokenField extends Exo.View
  name: "web/components/token_field/token_field"
  tagName: "ul"
  className: "token-field"
  maxTokens: Infinity
  placeholder: ""

  events:
    "blur input": "_blur"
    "focus input": "focus"
    "keypress input": "_keypress"
    "click": "_click"
    "click input": "_clickInput"
    "keypress input": "_keypress"
    "mousedown li:not(.token-input)": (e) ->
      e.preventDefault()
    "click li.token-field-token": "_clickToken"
    "click .close": "_clickTokenDelete"

  minInputValueLength: 2

  @TokenIndexes:
    All: -3
    Input: -2

  initialize: (options = {}) ->
    super
    @selectedIndex = TokenField.TokenIndexes.Input
    @tokens = new ArrayController()
    @tokens.comparator = null
    @properties = []
    @tokens.on("all", @_tokensChanged, this)

    @tokenTemplates =
      string: (obj) ->
        return unless _.isString(obj)
        templateName = "#{@name}_item"
        context = { name: obj }
        @template(templateName, context)

  render: ->
    # In case this is a re-render, remove the token-input
    $(@container).remove() if @container

    @container = document.createElement("li")
    @container.className = "token-input"

    @input = document.createElement("input")
    @input.setAttribute("autocorrect", "off")
    @input.setAttribute("autocapitalize", "off")
    @input.setAttribute("autocomplete", "off")
    @input.setAttribute("tabindex", "0")

    @inputPlaceholder = document.createElement("span")
    @inputPlaceholder.className = "input-placeholder"

    @inputCopy = document.createElement("span")
    @inputCopy.className = "input-copy"

    @_setPlaceholder()

    @$input = $(@input)

    @_toggleInputVisibility()

    @container.appendChild(@input)
    @container.appendChild(@inputPlaceholder)
    @container.appendChild(@inputCopy)

    for property in @properties
      @el.appendChild(property.node)

    @el.appendChild(@container)

    this

  insertToken: (tokens, disableDelete = false) ->
    return if @maxTokensExceeded()

    tokens = if _.isArray(tokens) then tokens.slice() else [tokens]

    @render() if !@container

    for token in tokens
      token = @_prepareObject(token, disableDelete)
      unless @tokens.include(token.object)
        @el.insertBefore(token.properties.node, @container)
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
      @el.removeChild(node)
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
    newProperties, newTokens = [], []

    for item, index in @properties
      if item.disableDelete
        newProperties.push item
        newTokens.push @tokens.at(index)
      else
        @el.removeChild(item.node)

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
    Flow.keyboardManager.nominate this

  isFocused: ->
    @$el.hasClass("focus")

  maxTokensExceeded: ->
    @tokens.length >= @maxTokens

  destroy: ->
    Flow.keyboardManager.revoke this
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
        return false

    @_updateInput(e)
    undefined

  _updateInput: (e) ->
    return unless @input

    value = if e
      Flow.Helpers.EstimateInputValue(@input.value, e, {
        insert: true
        target: @input
        multipleLines: false
      })
    else
      @input.value
    @inputCopy.textContent = value || ""
    @$el.toggleClass("has-input", (value.length > 0))

  _keypress: (e) ->
    key = Flow.Helpers.keyNameForCode(e.keyCode)
    if key == "enter"
      value = @helpers.sanitizeForRegex(@input.value)
      if value.length >= @minInputValueLength
        @tokenize(value)
        e.preventDefault()

    if key in ["left", "right", "up", "down", "delete", "backspace"]
      return

    if @selectedIndex != TokenField.TokenIndexes.Input
      @deleteTokenAtIndex(@selectedIndex, true)
      @selectedIndex = TokenField.TokenIndexes.Input
      @selectTokenAtIndex(TokenField.TokenIndexes.Input)

    @trigger("keypress", e)

  _blur: (e) ->
    Flow.keyboardManager.revoke this

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

  _prepareObject: (object, disableDelete) ->
    data = @helpers.templateForObject(object, @tokenTemplates, this)
    if _.isString data
      node = document.createElement("li")
      node.innerHTML = data
      node = node.firstChild

    properties = {node : node || data, disableDelete: disableDelete}
    token = {object: object, properties: properties}
    $(token.properties.node).addClass("disable-delete") if disableDelete

    return token

  _tokensChanged: (token) ->
    @_setPlaceholder() if @inputPlaceholder
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

