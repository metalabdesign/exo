#= require ./popover
namespace 'Exo.Views', (exports) ->
  class exports.CollectionListPopover extends Exo.Views.Popover
    @mixins : ["selectable"]
    selectableSelector: ".collection-item"

    events:
      "mousedown li" : "_itemClicked"
      "show" : "_nominateKeyboardManager"
      "hide" : "_revokeKeyboardManager"

    name: "collection_list_popover"
    className: "collection-list-popover popover"

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

    #
    # Private
    #

    _modelSelected: (model) ->
      @trigger("item:selected", model)

    _itemClicked: (e) ->
      cid = $(e.currentTarget).closest("li")[0].getAttribute("data-model-cid")
      @_modelSelected(@collection.get(cid))
      @hide()

    _nominateKeyboardManager: ->
      @keyboardManager.nominate this

    _revokeKeyboardManager: ->
      @keyboardManager.revoke this
