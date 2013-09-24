@Exo ||= {}
@Exo.Views ||= {}

namespace 'Exo', (exports) ->
  class exports.View extends Thorax.View
    Thorax.Util.resetInheritVars(this)
