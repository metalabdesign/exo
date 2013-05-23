namespace 'Exo', (exports) ->
  class exports.Matcher
    constructor: (options = {}) ->
      options = _.defaults(options, threshold: 0.1)
      @results = new Exo.ArrayController()
      @results.comparator = null
      @sources = []
      @threshold = options.threshold

    resultsForString: (query) ->
      results = []

      for source in @sources

        source.each (model) =>
          return unless model

          # Score models in sources against a passed in query if there is one,
          # otherwise return all models
          if query
            throw "No search key defined on #{model}" unless model.searchKey
            score = @_scoreForQuery(model.get(model.searchKey), query)

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

    _scoreForQuery: (string, abbreviation, fuzziness = null) ->
      # If the string is equal to the abbreviation, perfect match.
      return 1 if string == abbreviation

      #if it's not a perfect match and is empty return 0
      return 0 if abbreviation is ""

      total_character_score = 0
      abbreviation_length = abbreviation.length
      string_length = string.length
      start_of_string_bonus = undefined
      abbreviation_score = undefined
      fuzzies = 1
      final_score = undefined

      # Walk through abbreviation and add up scores.
      i = 0
      character_score = undefined
      index_in_string = undefined
      c = undefined
      index_c_lowercase = undefined
      index_c_uppercase = undefined
      min_index = undefined

      # = 0
      # = 0
      # = ''
      # = 0
      # = 0
      # = 0
      while i < abbreviation_length

        # Find the first case-insensitive match of a character.
        c = abbreviation.charAt(i)
        index_c_lowercase = string.indexOf(c.toLowerCase())
        index_c_uppercase = string.indexOf(c.toUpperCase())
        min_index = Math.min(index_c_lowercase, index_c_uppercase)
        index_in_string = (if (min_index > -1) then min_index else Math.max(index_c_lowercase, index_c_uppercase))
        if index_in_string is -1
          if fuzziness
            fuzzies += 1 - fuzziness
            continue
          else
            return 0
        else
          character_score = 0.1

        # Set base score for matching 'c'.

        # Same case bonus.
        character_score += 0.1  if string[index_in_string] is c

        # Consecutive letter & start-of-string Bonus
        if index_in_string is 0

          # Increase the score when matching first character of the remainder of the string
          character_score += 0.6

          # If match is the first character of the string
          # & the first character of abbreviation, add a
          # start-of-string match bonus.
          start_of_string_bonus = 1  if i is 0 #true;
        else

          # Acronym Bonus
          # Weighing Logic: Typing the first character of an acronym is as if you
          # preceded it with two perfect character matches.
          # * Math.min(index_in_string, 5); // Cap bonus at 0.4 * 5
          character_score += 0.8  if string.charAt(index_in_string - 1) is " "

        # Left trim the already matched part of the string
        # (forces sequential matching).
        string = string.substring(index_in_string + 1, string_length)
        total_character_score += character_score
        ++i
      # end of for loop

      # Uncomment to weigh smaller words higher.
      # return total_character_score / string_length;
      abbreviation_score = total_character_score / abbreviation_length

      #percentage_of_matched_string = abbreviation_length / string_length;
      #word_score = abbreviation_score * percentage_of_matched_string;

      # Reduce penalty for longer strings.
      #final_score = (word_score + abbreviation_score) / 2;
      final_score = ((abbreviation_score * (abbreviation_length / string_length)) + abbreviation_score) / 2
      final_score = final_score / fuzzies
      final_score += 0.15  if start_of_string_bonus and (final_score + 0.15 < 1)
      final_score

