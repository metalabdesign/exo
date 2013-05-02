class @Exo.TouchStack extends Exo.Stack

  constructor: (@size = 10, @axis = null) ->
    super

  push: (item) ->
    if (last = @last()) && @axis
      dir = direction(item, @last())
      @reset() if @lastDirection?[@axis] != dir[@axis]
      @lastDirection = dir

    # The `touches` objects on mobile safari are _not cloned_ per event by default.
    # They are references to the same object that changes over the course of the
    # touch moveing.
    #
    # That means that the coordinates on the same touch object across events always
    # reflect the last time it was updated when we're accessing historical events
    # like this.
    clone = {
      originalEvent: item
      touches: (_.clone(touch) for touch in item.touches)
    }

    super(clone)

  momentum: ->
    first = @first()
    last = @last()

    elapsed = last.originalEvent.timeStamp - first.originalEvent.timeStamp
    diffX = last.touches[0].pageX - first.touches[0].pageX
    diffY = last.touches[0].pageY - first.touches[0].pageY

    {
      x: diffX / elapsed
      y: diffY / elapsed
      speed:
        x: Math.abs diffX / (diffX / elapsed)
        y: Math.abs diffY / (diffY / elapsed)
    }

  direction: ->
    direction @first(), @last()

direction = (a, b) ->
  diffX = b.touches[0].pageX - a.touches[0].pageX
  diffY = b.touches[0].pageY - a.touches[0].pageY

  {
    x: diffX && (diffX >> 30) | 1
    y: diffY && (diffY >> 30) | 1
  }
