namespace 'Exo.Views', (exports) ->
  class exports.Modal extends Exo.View
    name: "modal"

    className: "modal"

    # @todo all of these
    width: null
    height: "auto"
    appendTo: document.body
    appendOverlayTo: document.body
    modal: true
    visible: false
    scrollable: true
    zIndex: 1024
    destroyOnHide: false
    escToClose: true

    topOffset:  "80px"

    headerSelector:  "> .modal-header"
    sidebarSelect:   "> .modal-sidebar"
    contentSelector: "> .modal-content"
    footerSelector:  "> .modal-footer"

    initialize: ->
      # @param content [String, Backbone.View] optional content to append to modal-content
      @content ||= null
      
      # @todo
      @dimensions ||= { width: null, height: null }

      @keyboardManager ||= new Exo.KeyboardManager(@el)

    positionElement: ->
      @_setHeight()
      @_setWidth()

      @$el.css(
        top: @topOffset
        left: "50%"
        marginLeft: "-#{ @dimensions.width / 2 }px"
      )

      this

    handleKeyUp: (key, e) ->
      switch key
        when "esc"
          @hide() if @escToClose
      false

    getOverlay: ->
      @_overlay ||= $("<div class='modal-overlay'></div>").css(zIndex: @zIndex - 1).appendTo(@appendOverlayTo)

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
      @keyboardManager.nominate(this)
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
      @destroy() if @destroyOnHide
      this

    toggle: ->
      if @visible
        @hide()
      else
        @show()

    render: ->
      super

      @$header  = @$(@headerSelector)
      @$content = @$(@contentSelector)
      @$sidebar = @$(@sidebarSelector)
      @$footer  = @$(@footerSelector)

      @$el.css(zIndex: @zIndex)
      @$el.addClass("not-scrollable") unless @scrollable

      @$el.addClass("with-footer") if @$footer.length
      @$el.addClass("with-sidebar") if @$sidebar.length

      if content = (@content?.el || @content)
        content.style.display = "block"
        @$content.append(content)

      return this

    remove: ->
      @_overlay?.remove()
      super

    destroy: ->
      super
      @keyboardManager.revoke(this)

    # 
    # Private
    #
    
    _detectHeightForPositioning: ->
      @$el.height()

    _setHeight: ->
      headerHeight = @$header.outerHeight()
      footerHeight = @$footer.outerHeight()

      setHeight = (height) =>
        @dimensions.height = height
        @$el.height height

        @$content.css(position: "absolute")
        @$footer.css(position: "absolute")

        @$content.add(@$sidebar).css
          top: headerHeight
          bottom: footerHeight

      if @height == "auto"
        @$el.css(height: "auto")
        @$content.css(position: "relative", top: 0)
        @$footer.css(position: "static")

        elHeight = @_detectHeightForPositioning()
        # TODO magic number
        maxHeight = window.innerHeight - 160

        contentHeight = @$content.height()

        if (contentHeight + @$footer.height() + headerHeight) >= maxHeight
          setHeight maxHeight
        else if @$sidebar.length || contentHeight == 0
          setHeight elHeight

      else
        setHeight @height

    _setWidth: ->
      if @width == "auto"
        @$el.css(width: "auto")
        @$content.css(position: "relative")
        @dimensions.width = @$el.width()
      else if @width
        @dimensions.width = @width
        @$el.width @width
