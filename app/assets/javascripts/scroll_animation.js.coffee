class @ScrollAnimation
  windowHeight   = window.innerHeight
  documentHeight = null
  lastTop        = null

  update = ->
    scrollTop = document.documentElement.scrollTop or document.body.scrollTop
    return if scrollTop is lastTop
    for anim in ScrollAnimation.animations
      anim?.animate(scrollTop, windowHeight, documentHeight)

    lastTop = scrollTop

  run = ->
    requestAnimationFrame(run)
    update()

  @animations: []

  @register: (args...) ->
    if args[0] instanceof ScrollAnimation
      @animations.push(args[0])
    # else
      # TODO

  @remove: (instance) ->
    idx = @animations.indexOf instance
    return null if idx < 0
    @animations.splice idx, 1

  @start: ->
    ScrollAnimation.refresh()
    $(window).on("resize", ScrollAnimation.refresh)

    if Modernizr.touch
      document.addEventListener("touchstart", update)
      document.addEventListener("touchmove", update)
      document.addEventListener("touchend", update)

    run()

  @refresh: ->
    windowHeight        = window.innerHeight
    documentHeight      = $(document).height()
    lastTop             = 0

    anim.resize() for anim in ScrollAnimation.animations
    this

  STATE_IDLE = 0
  STATE_ANIMATING = 1

  constructor: ({@el, @animation, @reset, offset}) ->
    @offset = offset || -> 0
    offset = @offset(windowHeight)

    @resize(windowHeight)
    @state = STATE_IDLE

  resize: (viewportHeight) ->
    top = $(@el).offset()['top']
    @start = top + @offset(viewportHeight)
    @height = @el.offsetHeight
    @end = @height + @start

  animate: (scrollTop, windowHeight, documentHeight) ->
    unless (@start > scrollTop && @end < (scrollTop + windowHeight))
      if @state == STATE_ANIMATING
        @reset?()
        @state = STATE_IDLE

    @state = STATE_ANIMATING
    @animation.apply(this, Array::slice.call(arguments))

