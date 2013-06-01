#= require ./popover
namespace 'Exo.Views', (exports) ->
  class exports.CollectionListPopover extends Exo.Views.Popover
    events:
      "click li" : "_itemClicked"

    name: "collection_list_popover"
    className: "collection-list-popover popover"

    #
    # Private
    #

    _itemClicked: (e) ->
      cid = $(e.currentTarget).closest("li")[0].getAttribute("data-model-cid")
      @trigger("item:selected", @_modelForCid(cid))
