callback = ->
  @on "click [data-action]": (e) ->
    el = e.currentTarget
    action = el.getAttribute "data-action"
    @handleAction action, el, e

# Implement handleAction in sub class
Exo.View.registerMixin "actions", callback, {}
