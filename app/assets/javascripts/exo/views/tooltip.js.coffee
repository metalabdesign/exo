class @Exo.Views.Tooltip extends Exo.View
  name: "tooltip"

  className: "tooltip"

  width: null
  height: "auto"
  allowHoverOnTooltip: true
  appendTo: document.body
  setupEvents: true

  visible: false

  initialize: ->
    super

    @on "destroyed", @_onDestroyed, this

    if @target
      target = @target
      @target = null
      @setTarget(target)

  _onDestroyed: ->
    @hide()
    @$target.off(".popover-#{@cid}") if @target
    $(window).off(".popover-#{@cid}")
    $(document).off(".popover-#{@cid}")

  setTarget: (target) ->
    if @target
      @$target.off(".popover-#{@cid}")

    @target = target[0] || target
    @$target = $ @target

    @_setupEvents() if @setupEvents
    @_setupPosition()

  _setupEvents: ->
    @$target.on "mouseenter.popover-#{@cid}", (e) =>
      e.preventDefault()
      @show()

    @$target.on "mouseleave.popover-#{@cid}", (e) =>
      if !@allowHoverOnTooltip || (e.toElement != @$el[0] && !$(e.toElement).closest(@el).length)
        @hide()

    if @allowHoverOnTooltip
      @$el.on "mouseleave.popover-#{@cid}", (e) =>
        if (e.toElement != @$el[0] && !$(e.toElement).closest(@el).length)
          @hide()

  _setupPosition: ->
    @_position = _.extend {
      my: "center top"
      at: "center bottom"
      of: @$target
      offset: "0 0"
      collision: "flip"
    }, @position

    @_position.tail = _.extend {
      type: "top"
      my: "center bottom"
      at: "center top"
      offset: "0 0"
    }, @position?.tail

    @_position.tail.of = @el unless @_position.tail.of

  # TODO: Add window max height detection
  positionElement: (position) ->
    $content = @$("> .content")

    if @height == "auto"
      @$el.css(height: "auto")
      $content.css(position: "relative")
      @$("> footer").css(position: "static")
    else
      @$el.height @height
      $content.css
        top: @$("> header").outerHeight()
        bottom: @$("> footer").outerHeight()

    if @width == "auto"
      @$el.css(width: "auto")
      $content.css(position: "relative")
    else if @width
      @$el.width @width

    if position
      tail_pos = _.extend {}, @_position.tail, position.tail
      position = _.extend {}, @_position, position
      position.tail = tail_pos
      position.tail.of = @el unless position.tail.of
    else
      position = _.clone @_position
      position.tail = _.clone @_position.tail

    @$el.position position

    $tail = @$(".tooltip-tail")
    $tail.attr("class", "tooltip-tail #{ position.tail.type }")
    $tail.position position.tail

    $tail.hide() if @tail == false

    this

  show: (position) ->
    return this if @visible

    @render() unless @_renderCount
    @$el.appendTo(@appendTo) unless @el.parentNode == @appendTo

    @_boundPositionElement ||= _.bind @positionElement, this
    $(window).on("resize.popover-#{@cid}", @_boundPositionElement)

    @visible = true
    @$el.show()
    @positionElement(position)
    @trigger "show"

  hide: (e) ->
    return this unless @visible

    if e
      e.preventDefault()
      e.stopPropagation()

    $(window).off("resize.popover-#{@cid}", @_boundPositionElement)

    @visible = false
    @$el.hide()
    @trigger "hide"

  toggle: ->
    if @visible
      @hide()
    else
      @show()

  render: ->
    super

    if @content
      @$("> .content").append(@content.el || @content).appendTo(@el)

    $("<div class='tooltip-tail'><div></div></div>").appendTo(@el)

    this
