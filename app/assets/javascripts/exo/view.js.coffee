@Exo ||= {}
@Exo.Views ||= {}

namespace 'Exo', (exports) ->
  class exports.View extends Thorax.View

    # 
    # Private
    #
    
    _modelForCid: (cid) ->
      if @collection
        # Can't use @collection.findByCid because @collection could be an ArrayController
        @collection.detect (m) -> m.cid == cid
      else
        throw "No collection specified"
