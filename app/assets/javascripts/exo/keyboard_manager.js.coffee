namespace 'Exo', (exports) ->
  keyboardManager = class exports.KeyboardManager

    _map = {
      8: 'backspace'
      9: 'tab'
      12: 'clear'
      13: 'enter'
      27: 'esc'
      32: 'space'
      37: 'left'
      38: 'up'
      39: 'right'
      40: 'down'
      46: 'delete'
      36: 'home'
      35: 'end'
      33: 'pageup'
      34: 'pagedown'
      188: ','
      190: '.'
      191: '/'
      192: '`'
      189: '-'
      187: '='
      186: ';'
      222: '\''
      219: '['
      221: ']'
      220: '\\'
    }

    _modifiers = {
      '⇧': 16, shift: 16,
      '⌥': 18, alt: 18, option: 18,
      '⌃': 17, ctrl: 17, control: 17,
      '⌘': 91, command: 91
    }

    @isNonPrintableKey = (keyCode) ->
      modifierKeys = [8, 9, 13, 16, 17, 18, 19, 20, 27, 33, 34, 35, 26, 46, 93]
      arrowKeys = [37, 38, 39, 40, 91, 92]
      fKeys = [112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 144, 145]
      keyCode in [modifierKeys..., arrowKeys..., fKeys]

    @isPrintableKey = (keyCode) ->
      !keyboardManager.isNonPrintableKey(keyCode)

    @keyStringFromEvent = (e) ->
      keys = []
      keys.push '⇧' if e.shiftKey
      keys.push '⌥' if e.altKey
      keys.push '⌃' if e.ctrlKey
      keys.push '⌘' if e.metaKey

      if _map[e.keyCode]
        keys.push _map[e.keyCode]
      else
        keys.push String.fromCharCode e.keyCode

      keys.join '+'

    constructor: (@el = null) ->
      @_responders = []
      @cid = _.uniqueId("k")

      @el ||= document
      @$el = $(@el)

      boundDispatch = $.proxy(this, "_dispatch")
      @$el.on("keyup.#{ @cid }", boundDispatch)
          .on("keydown.#{ @cid }", boundDispatch)

    _dispatch: (e) ->
      # exit early if no responders
      return this if not @_responders.length

      # exit early if it's just a modifier key all by itself
      return if e.keyCode in [16, 18, 17, 91]

      str = KeyboardManager.keyStringFromEvent e

      if e.type == "keydown"
        @_handleKey("handleKeyDown", str, e)
      else if e.type == "keyup"
        @_handleKey("handleKeyUp", str, e)

      this

    _handleKey: (handlerMethod, key, e) ->
      for responder in @_responders
        ret = responder[handlerMethod]?(key, e)
        return false if ret == false || e.isPropagationStopped()

      undefined

    firstResponder: ->
      @_responders[0]

    nominate: (responder) ->
      # Remove responder, make it first responder
      idx = @_responders.indexOf responder
      @_responders.splice idx, 1 if idx > -1
      @_responders.unshift responder
      this

    revoke: (responder) ->
      idx = @_responders.indexOf responder
      return this if idx < 0
      @_responders.splice idx, 1
      this

    destroy: ->
      @$el.off("keyup.#{ @cid }")
          .off "keydown.#{ @cid }"
      @_responders = null
