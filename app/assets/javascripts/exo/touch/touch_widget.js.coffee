TouchWidget = class @Exo.Touch.Widget extends Exo.Widget

  defaults: {}

  constructor: (el, options) ->
    super
    @setTarget(@el)

    @origin = @_getPosition()

    @axis = @options.axis
    @oppositeAxis = TouchWidget.oppositeAxis @axis

    @setDimensions
      x: @options.x || @el.offsetWidth
      y: @options.y || @el.offsetHeight

  setTarget: (element) ->
    @$target = if element instanceof $ then element else $(element)
    @target = @$target[0]

  setDimensions: (hash) ->
    @dimensions = hash
    @el.style.width = @dimensions.x + "px"
    @el.style.height = @dimensions.y + "px"

    @duration = @dimensions[@axis] * 0.6 # TODO make configurable

    this

  _setPosition: (pos, animate = false, ease = "ease", callback) ->
    if animate
      @target.style.webkitTransitionProperty = "-webkit-transform"
      @target.style.webkitTransitionDuration = "#{(if animate == true then @duration else animate)}ms"
      @target.style.webkitTransitionTimingFunction = ease

      @target.addEventListener "webkitTransitionEnd", (e) =>
        if typeof e != "undefined"
          return if e.target != e.currentTarget  # makes sure the event didn't bubble from "below"
          e.target.removeEventListener "webkitTransitionEnd", arguments.callee

        @target.style.webkitTransitionProperty =
        @target.style.webkitTransitionDuration =
        @target.style.webkitTransitionTimingFunction = ""
        callback?()

    @target.style.webkitTransform = "translate3d(#{ TouchWidget.positionToTranslate pos })"
    callback?() unless animate

    @_currentPosition = pos

    this

  _getPosition: ->
    @_currentPosition ||= if @target.style.webkitTransform
      TouchWidget.positionFromTranslate(@target.style.webkitTransform)
    else
      TouchWidget.positionFromMatrix(new WebKitCSSMatrix(getComputedStyle(@target).webkitTransform))


# Utility methods

  @oppositeAxis: (a) ->
    if a == "x" then "y" else "x"

  @positionFromTranslate: (str) ->
    [a, x, y, z] = str.match(/\((\d+)px,\s?(\d+)px,\s?(\d+)(?:px)?\)$/)
    {x, y}

  @positionFromMatrix: (m) ->
    {x: m.e,  y: m.f}

  @positionToTranslate: (pos) ->
    "#{ pos.x || 0 }px, #{ pos.y || 0 }px, 0"

  @positionGreater: (a, b) ->
    a.x >= b.x && a.y >= b.y

  @positionLess: (a, b) ->
    a.x <= b.x && a.y <= b.y

  @addPosition: (a, b) ->
    {
      x: a.x + b.x
      y: a.y + b.y
    }

  @subPosition: (a, b) ->
    {
      x: a.x - b.x
      y: a.y - b.y
    }

  @getPosition: (event) ->
    {
      x: event.pageX || event.touches[0].pageX
      y: event.pageY || event.touches[0].pageY
    }



