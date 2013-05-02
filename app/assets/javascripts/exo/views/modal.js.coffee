class @Exo.Views.Modal extends Exo.View
  name: "modal"

  className: "modal"

  width: null
  height: "auto"
  appendTo: document.body
  modal: true
  visible: false
  scrollable: true
  zIndex: 1024

  positionElement: ->
    @dimensions ||= { width: null, height: null }

    $header = @$("> .modal-header")
    $content = @$("> .modal-content")
    $sidebar = @$("> .modal-sidebar")
    $footer  = @$("> .modal-footer")

    headerHeight = $header.outerHeight()

    setHeight = (height) =>
      @dimensions.height = height
      @$el.height height

      $content.css(position: "absolute")
      $footer.css(position: "absolute")

      $content.add($sidebar).css
        top: headerHeight
        bottom: $footer.outerHeight()

    if @height == "auto"
      @$el.css(height: "auto")
      $content.css(position: "relative")
      $footer.css(position: "static")

      elHeight = @_detectHeightForPositioning()
      maxHeight = window.innerHeight - 160

      contentHeight = $content.height()
      if (contentHeight + $footer.height() + headerHeight) >= maxHeight
        setHeight maxHeight
      else if $sidebar.length || contentHeight == 0
        setHeight elHeight

    else
      setHeight @height

    if @width == "auto"
      @$el.css(width: "auto")
      $content.css(position: "relative")
      @dimensions.width = @$el.width()
    else if @width
      @dimensions.width = @width
      @$el.width @width

    @$el.css(
      top: "80px"
      left: "50%"
      marginLeft: "-#{ @dimensions.width / 2 }px"
    )

    this

  _detectHeightForPositioning: ->
    @$el.height()

  getOverlay: ->
    @_overlay ||= $("<div class='modal-overlay'></div>").css(zIndex: @zIndex - 1).appendTo(document.body)

  scrollTo: (pos) ->
    # TODO support elements, += values, etc.
    @$("> .modal-content").scrollTop pos

  show: ->
    @render() unless @_renderCount

    @$el.appendTo(@appendTo) unless @el.parentNode == @appendTo

    @_boundPositionElement ||= _.bind(@positionElement, this)
    $(window).on "resize.modal-#{@cid}", @_boundPositionElement

    @visible = true
    @getOverlay().show() if @modal
    @$el.show()
    @positionElement()
    @trigger "show"

  hide: (e) ->
    if e
      e.preventDefault()
      e.stopPropagation()

    $(window).off "resize.modal-#{@cid}", @_boundPositionElement

    @visible = false
    @$el.hide()
    @getOverlay().hide()
    @trigger "hide"

  toggle: ->
    if @visible
      @hide()
    else
      @show()

  render: ->
    super

    @$el.css(zIndex: @zIndex)
    @$el.addClass("not-scrollable") unless @scrollable

    @$el.addClass("with-footer") if @$("> .modal-footer").length
    @$el.addClass("with-sidebar") if @$("> .modal-sidebar").length

    if @content
      @$("> .modal-content").append(@content.el || @content)

    return this

  remove: ->
    @_overlay?.remove()
    super

