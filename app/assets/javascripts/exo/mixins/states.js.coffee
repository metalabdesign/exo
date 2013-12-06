callback = ->
  @on "rendered", =>
    if @_renderCount == 1
      @transitionTo @initialState, force: true

Exo.View.registerMixin "states", callback,
  transitionTo: (state, options = {}) ->
    return this if state == @state && !options.force

    @lastState = @state
    # ~= http://api.jquery.com/attribute-contains-word-selector/
    @$("[data-state]").hide().filter("[data-state~='#{ state }']").show()
    @state = state
    @trigger "change:state", @state, @lastState, options unless options.silent
    this
