#= require exo/extensions/string

namespace 'Exo', (exports) ->
  class exports.Matcher
    constructor: (options = {}) ->
      options = _.defaults(options, threshold: 0.2)
      @results = new Exo.ArrayController()
      @results.comparator = null
      @sources = []
      @threshold = options.threshold
      @modelFilterAttr = options.filterAttribute || "name"

    resultsForString: (query) ->
      results = []

      for source in @sources
        source.each (model) =>
          return unless model

          # Score models in sources against a passed in query if there is one,
          # otherwise return all models
          if query
            score = exports.Extensions.String.score(model.get(@modelFilterAttr), query)

            if score > @threshold
              results.push {
                score: score
                object: model
              }
          else
            results.push {
              score: null
              object: model
            }

        continue

      # Sort result objects by score, then pluck and return just the model
      results.sort((a,b) -> b.score - a.score)
      results = _.pluck(results, "object")
      @results.reset results

      return @results

    addSource: (source) ->
      @sources.push(source)
