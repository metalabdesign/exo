namespace 'Exo', (exports) ->
  class exports.Stack

    constructor: (@size = 10) ->
      @reset()

    push: (item) ->
      @pop() while @ary.length + 1 > @size
      @length = @ary.push(item)

    pop: ->
      item = @ary.pop()
      @length = @ary.length
      item

    reset: ->
      @ary = []
      @length = 0

    first: -> @ary[0]

    last: -> @ary[@ary.length - 1]
