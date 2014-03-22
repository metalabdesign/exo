#= require exo/extensions/string

namespace 'Exo', (exports) ->
  class exports.Matcher
    constructor: (options = {}) ->
      options = _.defaults(options, threshold: 0.2)
      @sources = []
      @threshold = options.threshold
      @modelFilterAttr = options.filterAttribute || "name"
      this

    # @returns {Array.<Object>}
    resultsForString: (query, callback) =>
      results = []

      for source in @sources
        source.each (model) =>
          return unless model

          # Score models in sources against a passed in query if there is one,
          # otherwise return all models
          if query
            if attr = model.get(@modelFilterAttr)
              score = exports.Extensions.String.score(attr, query)

              if score > @threshold
                results.push
                  score: score
                  model: model
          else
            results.push
              score: null
              model: model

        continue

      # Sort result objects by score before returning
      results.sort((a, b) -> b.score - a.score)
      callback(results)

    addSource: (source) ->
      @sources.push(source)

    setSource: (source) ->
      @setSources([source])

    setSources: (sources) ->
      @sources = sources
