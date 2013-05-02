#= require exo/touch_widget

class @Exo.Widgets.Carousel extends Exo.TouchWidget

  cancelBubble = (e) ->
    e.stopImmediatePropagation()
    e.preventDefault()

  events:
    "touchmove [data-action]": cancelBubble
    "touchend [data-action]": cancelBubble

    "touchstart [data-action='next']": (e) ->
      cancelBubble(e)
      @next()

    "touchstart [data-action='prev']": (e) ->
      cancelBubble(e)
      @prev()

    "click [data-action='to']": (e) ->
      cancelBubble(e)
      idx = parseInt(e.currentTarget.getAttribute("data-index"), 10)
      @to idx

    "touchmove": "_onTouchMove"
    "touchend": "_onTouchEnd"

  defaults:
    minSpeed: 180

  constructor: (el, options) ->
    super

    @setTarget @$el.find ".carousel-items"

    @length = @$items.length
    @el.setAttribute "data-carousel-length", @length

    @renderIndicators()
    @renderControls()

    @to 0, false

  setDimensions: (hash) ->
    super

    (@$items ||= @$el.find ".carousel-item").each (i, el) =>
      el.style.left = "#{ (@dimensions[@axis] + @options.itemSpacing) * i }px"

    this

  _onTouchMove: (e) ->
    e = e.originalEvent

    unless @_stack
      @_stack = new TouchStack(4)
      @_startOffset = TouchWidget.subPosition TouchWidget.getPosition(e), @_currentPosition

    @_stack.push e

    if @_stack.length > 3
      momentum = @_stack.momentum()
      movingAlongAxis = Math.abs(momentum[@axis]) > Math.abs(momentum[@oppositeAxis])
      e.preventDefault() if movingAlongAxis

    # apply offset from touchstart relative to container origin, so we don't get
    # an initial "jump" from where the finger is vs. origin
    delta = TouchWidget.subPosition TouchWidget.getPosition(e), @_startOffset
    delta[@oppositeAxis] = 0
    @_setPosition delta, false

  _onTouchEnd: (e) ->
    e = e.originalEvent
    e.currentTarget.removeEventListener "touchmove", @_boundMove
    momentum = @_stack.momentum()
    direction = @_stack.direction()
    speed = momentum.speed[@axis]
    speed = @options.minSpeed if speed < @options.minSpeed
    ease = "cubic‑bezier(0,.74,.36,.88)"

    movingAlongAxis = Math.abs(momentum[@axis]) > Math.abs(momentum[@oppositeAxis])
    idx = if movingAlongAxis then @currentIdx + direction[@axis] * -1 else @currentIdx

    @_stack = null
    @to idx, speed, ease

  renderIndicators: ->
    return unless @options.indicators

    if (existing = @$el.find(".carousel-indicators")) && existing.length
      @$indicatorContainer = existing.empty()
      @indicatorContainer = @$indicatorContainer[0]
    else
      @indicatorContainer = document.createElement "div"
      @indicatorContainer.className = "carousel-indicators"
      @$indicatorContainer = $ @indicatorContainer

    for n in [0..@length-1]
      el = document.createElement "div"
      el.className = "carousel-indicator"
      el.setAttribute "data-index", n
      @indicatorContainer.appendChild el

    @$indicators = @$indicatorContainer.children()
    @$el.append @indicatorContainer

  renderControls: ->
    @$el.find(".carousel-controls").toggle(@options.controls)
    @$el.toggleClass("with-controls", @options.controls)

  toggle: ->
    if @visible then @close() else @open()

  next: (animate = true, ease) -> @to @currentIdx + 1, animate, ease

  prev: (animate = true, ease) -> @to @currentIdx - 1, animate, ease

  to: (idx, animate = true, ease) ->
    idx = 0 if idx < 0
    idx = @length - 1 if idx >= @length

    idxChanged = idx != @currentIdx

    callback = if idxChanged
      =>
        @trigger "to:end", idx
        @$selectedIndicator?.removeClass("selected")
        @$selectedIndicator = @$indicators?.eq(idx).addClass("selected")
    else
      undefined

    @trigger "to:start", idx if idxChanged
    position = (@dimensions[@axis] + @options.itemSpacing) * -idx
    hash = {}
    hash[@axis] = position
    @_setPosition(hash, animate, ease, callback)
    @currentIdx = idx


Exo.Widget.register("carousel", Exo.Widgets.Carousel)

