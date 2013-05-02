@Exo ||= {}
@Exo.Mixins ||= {}

class @Exo.Mixins.Selectable

  selectableClass: 'selected'
  selectableDeselectOnClick: false

  initializeSelection: ->
    @lastSelected = false
    @shiftSelectIndex = 0

    # event = if Modernizr.touch then "touchstart" else "click"
    event = "click"

    $(@el).delegate @selectableSelector, event, (e) =>
      # document.activeElement.blur() if document.activeElement
      # e.stopPropagation()

      @shiftSelectIndex = 0

      elem = $(e.currentTarget)

      if e.metaKey || e.ctrlKey # command click
        @toggleSelection(elem)
      else if e.shiftKey # shift click
        if @lastSelected
          @deselectAll()
          @selectRange(@lastSelected, elem)
        else
          @lastSelected = elem
      else
        if @getSelectedElements().length > 1 && @isSelected(elem)
          @deselectOthers(elem)
        else
          @deselectOthers(elem, false)
          if @selectableDeselectOnClick then @toggleSelection(elem, false) else @select(elem, false)
          @notifySelectionChanged()

        @lastSelected = elem

  notifySelectionChanged: ->
    @trigger "selection:change", @getSelectedModels(), this

  isSelected: (elem) -> elem.hasClass(@selectableClass)

  select: (elem, notify = true) ->
    changes = elem.not(".#{@selectableClass}").addClass(@selectableClass)
    @notifySelectionChanged() if changes.length and notify
    return

  deselect: (elem, notify = true) ->
    changes = elem.filter(".#{@selectableClass}").removeClass(@selectableClass)
    @notifySelectionChanged() if changes.length and notify
    return

  selectRange: (start, end) ->
    all = @getItemsForSelection()
    a = if typeof start == 'number' then start else all.index(start)
    b = if typeof end == 'number' then end else all.index(end)
    b = Math.min(Math.max(0, b), all.length-1)

    if b < a
      @select all.slice(b, a+1)
    else
      @select all.slice(a, b+1)

    return

  selectInDirection: (dir, e) ->
    all = @getItemsForSelection().removeClass(@selectableClass)

    if e.shiftKey && @lastSelected
      @shiftSelectIndex += dir
      @selectRange(@lastSelected, all.index(@lastSelected) + @shiftSelectIndex)
    else
      @shiftSelectIndex = 0;
      i = (if @lastSelected then all.index(@lastSelected) else dir * -1) + dir
      i = Math.min(Math.max(0, i), all.length-1)
      @lastSelected = all.eq(i)
      @select @lastSelected

  selectAll: -> @select @getItemsForSelection()

  deselectAll: -> @deselect @getItemsForSelection()

  deselectOthers: (elem, notify = true) ->
    @deselect @getItemsForSelection().not(elem), notify

  toggleSelection: (elem, notify = true) ->
    if @isSelected(elem) then @deselect(elem, notify) else @select(elem, notify)

  getSelectedElements: -> @$("#{@selectableSelector}.#{@selectableClass}")

  getSelectedModels: ->
    _this = this
    @getSelectedElements().map () ->
      _this.collection.getByCid this.getAttribute("data-model-cid")

  getItemsForSelection: ->
    # TODO caching
    @$(@selectableSelector)

  selectByModel: (model) ->
    return if not model = @collection.get model
    @select $(model.el)
    this

  handleKey: (key, e) ->
    switch key
      when 'up', '⇧+up'
        @selectInDirection -1, e
        e.preventDefault()
      when 'down', '⇧+down'
        @selectInDirection 1, e
        e.preventDefault()

