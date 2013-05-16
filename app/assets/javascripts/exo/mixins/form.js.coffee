@Exo ||= {}
@Exo.Mixins ||= {}

namespace 'Exo.Mixins', (exports) ->
  class exports.Form

    showErrors: (allErrors, message=false) ->
      for namespace, errors of allErrors
        for field, error of errors
          @showError("#{ namespace }[#{ field }]", error, message)

      this

    hideErrors: ->
      @$(".form-base-error-messages .form-error-message").remove()
      @$(".error[name]").each (i, el) =>
        @hideError el.getAttribute "name"

      this

    showError: (field, error, message=false) ->
      if field == "base"
        if ($base = @$(".form-base-error-messages")).length > 0
          $base.append $("<div class='form-error-message'>#{ error }</div>")
        return this

      $input = @$("[name~='#{ field }']").addClass("error").attr("data-error", error)

      if message
        $parent = $input.parent()
        $message = $parent.find ".form-error-message"

        if $message.length == 0
          $message = $ "<div class='form-error-message'></div>"
          $parent.append $message

        $message.text error

      this

    hideError: (field) ->
      $input = @$("[name~='#{ field }']")

      $input.removeClass("error").removeAttr("data-error")

      $parent = $input.parent()
      $message = $parent.find ".form-error-message"

      if $message.length > 0
        $message.remove()

      this
