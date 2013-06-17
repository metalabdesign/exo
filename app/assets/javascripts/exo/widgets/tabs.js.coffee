namespace 'Exo.Widgets', (exports) ->
  class exports.Tabs extends Exo.Widget

    # Default options
    defaults:
      initialSelectedIndex: 0
      tabSelector:          "> .tab-nav a"
      contentBlockSelector: "> .tab-pane"
      closeable: false
      onSelect: ->

    # Shouldn't be overridden
    selectedClass:     "selected"

    # Helpers
    _indexForTabElem: (elem) -> @$navItems.index elem
    _tabAtIndex: (idx) -> if idx == -1 then $() else @$navItems.eq idx
    _contentBlockAtIndex: (idx) -> if idx == -1 then $() else @$contentBlocks.eq idx

    constructor: ->
      super

      # Find the content blocks
      @$contentBlocks = (@$el.find @options.contentBlockSelector)
       .attr role: "tabpanel"

      # Find the nav items
      @$navItems = (@$el.find @options.tabSelector)
       .attr role: "tab"

      # Setup tab item container attrs
      @$navItems.parent()
        .attr role: "tablist"

      # Configure Aria relations on tab items
      @$navItems.each (idx) =>
        $tab = (@_tabAtIndex idx)
          .attr tabindex: idx

        ($tab.attr id: _.uniqueId("exo-tabs")) unless $tab.attr('id')

        (@_contentBlockAtIndex idx)
          .attr "aria-labelledby": $tab.attr('id')

      # Find an already selected tab, or select the "initialSelectedIndex"
      preselectedItem = @$navItems.filter ".#{ @selectedClass }"
      @selectTab(
        if preselectedItem.length
          @_indexForTabElem(preselectedItem)
        else @options.initialSelectedIndex
      )

      # Coffeescript does not support string interpolation on hash literal keys
      events = {}
      events["click #{ @options.tabSelector }"] = "_clickedTabElem"
      @_delegateEvents events


    # Handle click event
    _clickedTabElem: (e, clickedElem) ->
      e.preventDefault()
      if $(e.currentTarget).hasClass(@selectedClass) && @options.closeable
        @selectTab -1
      else
        @selectTab (@_indexForTabElem e.currentTarget)

    # Select a tab by index
    selectTab: (idx) ->
      @$el.toggleClass 'closed', idx == -1

      (@$navItems.add @$contentBlocks)
        .removeClass @selectedClass

      (@_tabAtIndex idx)
        .add(@_contentBlockAtIndex(idx))
        .addClass @selectedClass

      @options.onSelect idx

      @$contentBlocks.attr "aria-hidden": "true"
      (@_contentBlockAtIndex idx).attr "aria-hidden": "false"


  Exo.Widget.register("tabs", Exo.Widgets.Tabs)
