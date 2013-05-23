_implements = (classes...) ->
  for klass in classes
    # static properties
    for prop of klass
      @[prop] = klass[prop]
    # prototype properties
    for prop of klass.prototype
      # Not supported on iOS < 5
      # Also non-standard and depreciated.
      # TODO: Replace with defineProperty etc.

      # getter = klass::__lookupGetter__(prop)
      # setter = klass::__lookupSetter__(prop)
      #
      # if getter || setter
      #     @::__defineGetter__(prop, getter) if getter
      #     @::__defineSetter__(prop, setter) if setter
      # else
      @::[prop] = klass::[prop]
  return this

# if Object.defineProperty
#   Object.defineProperty Function.prototype, "implements", value : implements
# else
Function::implements = _implements

