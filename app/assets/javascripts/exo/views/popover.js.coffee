#= require ./tooltip

namespace 'Exo.Views', (exports) ->
  class exports.Popover extends Exo.Views.Tooltip
    name: "popover"
    className: "popover"

    tail: true
    width: null
    height: "auto"
    appendTo: document.body
    activeClass: "active"
    clickOffToClose: true
    setupEvents: true

    initialize: ->
      _.bindAll this, "_onTargetClicked", "_onDocumentClicked"
      super

    _setupEvents: ->
      @$target.on("click.popover-#{ @cid }", @_onTargetClicked)

    _onTargetClicked: (e) ->
      $target = $(e.target)
      inTooltip = $target.closest(@$el).length
      return if inTooltip

      e.preventDefault()
      if @visible then @hide() else @show()

    _onDocumentClicked: (e) ->
      return true if not @visible or @clickOffToClose == false

      $target = $(e.target)

      inButton = $target.closest(@$target).length
      inTooltip = $target.closest(@$el).length

      @hide() if !inButton && !inTooltip

    show: ->
      $(document).on("click.popover-#{ @cid }", @_onDocumentClicked)
      @$target?.addClass @activeClass
      super

    hide: ->
      $(document).off("click.popover-#{ @cid }", @_onDocumentClicked)
      super
      @$target?.removeClass @activeClass
      return this
