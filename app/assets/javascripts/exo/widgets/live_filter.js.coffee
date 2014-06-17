#= require exo/extensions/string

namespace 'Exo.Widgets', (exports) ->
  class exports.LiveFilter extends Exo.Widget

    defaults:
      threshold: 0.6
      itemSelector: null
      itemContentSelector: null

    events:
      "keyup": "_keyup"

    constructor: ->
      super
      @cache()

    cache: ->
      match = @options.itemContentSelector
      @$items = $(@options.itemSelector)

      @_cache = for el in @$items.toArray()
        el = if match then $(match, el) else $(el)
        $.trim(el.text().toLowerCase())

    clear: ->
      @$el.val('').keyup()

    _keyup: (e) ->
      if e.which == 27 # Escape
        return @clear()

      query = $.trim(@$el.val().toLowerCase())
      scores = []

      if !query
        @$items.show()
      else
        @$items.hide()

        for text, i in @_cache
          score = Exo.Extensions.String.score text, query

          if score > @options.threshold
            scores.push [score, i]

        for result in scores.sort((a, b) -> b[0] - a[0])
          $(@$items[result[1]]).show()

  Exo.Widget.register("liveFilter", Exo.Widgets.LiveFilter)
