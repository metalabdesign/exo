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
            score = @_scoreForQuery(model.get(@modelFilterAttr), query)

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

    #
    # Private
    #

    _scoreForQuery: (string, query) ->
      #
      # Stolen from https://github.com/joshaven/string_score/blob/master/coffee/string_score.coffee
      #

      # **Size optimization notes**:
      # Declaring `string` before checking for an exact match
      # does not affect the speed and reduces size because `this`
      # occurs only once in the code as a result.
      #string = this
      
      # Perfect match if the string equals the query.
      return 1.0 if string == query

      # Initializing variables.
      string_length = string.length
      total_character_score = 0

      # Awarded only if the string and the query have a common prefix.
      should_award_common_prefix_bonus = 0.5
      
      #### Sum character scores
      
      # Add up scores for each character in the query.
      for c, i in query
          # Find the index of current character (case-insensitive) in remaining part of string.
          index_c_lowercase = string.indexOf c.toLowerCase()
          index_c_uppercase = string.indexOf c.toUpperCase()
          min_index = Math.min index_c_lowercase, index_c_uppercase
          index_in_string = if min_index > -1 then min_index else Math.max index_c_lowercase, index_c_uppercase        

          #### Identical strings
          # Bail out if current character is not found (case-insensitive) in remaining part of string.
          #
          # **Possible size optimization**:
          # Replace `index_in_string == -1` with `index_in_string < 0`
          # which has fewer characters and should have identical performance.
          return 0 if index_in_string == -1
          
          # Set base score for current character.
          character_score = 0.1
          
          #### Case-match bonus
          # If the current query character has the same case 
          # as that of the character in the string, we add a bonus.
          #
          # **Optimization notes**:
          # `charAt` was replaced with an index lookup here because 
          # the latter results in smaller and faster code without
          # breaking any tests.
          if string[index_in_string] == c
              character_score += 0.2
          
          #### Consecutive character match and common prefix bonuses
          # Increase the score when each consecutive character of
          # the query matches the first character of the 
          # remaining string.
          #
          # **Size optimization disabled (truthiness shortened)**:
          # It produces smaller code but is slower.
          #
          #     if !index_in_string
          if index_in_string == 0
              character_score += 0.8
              # String and query have common prefix, so award bonus. 
              #
              # **Size optimization disabled (truthiness shortened)**:
              # It produces smaller code but is slower.
              #
              #     if !i
              if i == 0
                  should_award_common_prefix_bonus = 1 #yes
          
          #### Acronym bonus
          # Typing the first character of an acronym is as
          # though you preceded it with two perfect character
          # matches.
          #
          # **Size optimization disabled**:
          # `string.charAt(index)` wasn't replaced with `string[index]`
          # in this case even though the latter results in smaller
          # code (when minified) because the former is faster, and 
          # the gain out of replacing it is negligible.
          if string.charAt(index_in_string - 1) == ' '
              character_score += 0.8 # * Math.min(index_in_string, 5) # Cap bonus at 0.4 * 5
          
          # Left trim the matched part of the string
          # (forces sequential matching).
          string = string.substring(index_in_string + 1, string_length)
   
          # Add to total character score.
          total_character_score += character_score
      
      # **Feature disabled**:
      # Uncomment the following to weigh smaller words higher.
      #
      #     return total_character_score / string_length
      
      query_length = query.length
      query_score = total_character_score / query_length
      
      #### Reduce penalty for longer strings
      
      # **Optimization notes (code inlined)**:
      #
      #     percentage_of_matched_string = query_length / string_length
      #     word_score = query_score * percentage_of_matched_string
      #     final_score = (word_score + query_score) / 2
      final_score = ((query_score * (query_length / string_length)) + query_score) / 2
      
      #### Award common prefix bonus
      if should_award_common_prefix_bonus and (final_score + 0.1 < 1)
          final_score += 0.1
      
      return final_score
