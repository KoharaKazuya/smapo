$ ->
  submitHandler = (event) ->
    $form = $(@)
    $form.off 'submit', submitHandler
    # form validation reset
    $('.has-error').removeClass 'has-error'
    $box = $('.flash-message-box')
    $box.empty()
    # generate data
    data = {}
    $($form.serializeArray()).each (i, v) ->
      data[v.name] = v.value
    $form.find(':checkbox').each ->
      data[@.name] = if @.checked then 1 else 0
    # post
    jQuery.ajax
      url: $form.data 'url'
      method: $form.data 'method'
      data: data
      success: (data) ->
        $redirect = $form.data 'redirect'
        if $redirect
          location.href = $redirect
        else
          $form.on 'submit', submitHandler
          $box.append $('<div>').addClass('alert').addClass('alert-success').text('送信に成功しました')
      error: (jqXHR) ->
        $form.on 'submit', submitHandler
        json = jqXHR.responseJSON
        if json?
          if json.error
            $box.append $('<div>').addClass('alert').addClass('alert-danger').text(json.error)
          if json.errors?
            for e in json.errors
              if (e.ValidationError?)
                for name, arr of e.ValidationError
                  $(".form-group:has(##{name})").addClass 'has-error'
    event.preventDefault()
  $('.main-form').on 'submit', submitHandler
