#= require ./popover
namespace 'Exo.Views', (exports) ->
  class exports.CollectionListPopover extends Exo.Views.Popover
    selectableSelector: ".collection-item"

    events:
      "show" : "_nominateKeyboardManager"
      "hide" : "_revokeKeyboardManager"

    name: "collection_list_popover"
    className: "collection-list-popover popover"

    initialize: ->
      @mixin "selectable"
      @on "mousedown #{ @selectableSelector }", @_itemClicked, this

      super

    handleKeyDown: (key, e) ->
      switch key
        when "up", "⇧+up"
          @selectPrevious(e)
          e.preventDefault()
        when "down", "⇧+down"
          @selectNext(e)
          e.preventDefault()
        when "tab", "⇧+tab"
          if model = @getSelectedModels()[0]
            @_modelSelected(model)
            @hide()
        when "enter"
          if model = @getSelectedModels()[0]
            @_modelSelected(model)
            e.preventDefault()
            e.stopPropagation()
            @hide()

      return

    # Private

    _modelSelected: (model) ->
      @trigger("item:selected", model)

    _itemClicked: (e) ->
      cid = e.currentTarget.getAttribute("data-model-cid")
      @_modelSelected(@collection.get(cid))
      @hide()

    _nominateKeyboardManager: ->
      @keyboardManager.nominate this

    _revokeKeyboardManager: ->
      @keyboardManager.revoke this
