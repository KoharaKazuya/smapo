$ ->
  $form = $ '.main-form'
  submitHandler = (event) ->
    $form.off 'submit', submitHandler
    # form validation reset
    $('.has-error').removeClass 'has-error'
    # generate data
    data = {}
    $($form.serializeArray()).each (i, v) ->
      data[v.name] = v.value
    # post
    jQuery.ajax
      url: $form.data 'url'
      method: 'post'
      data: data
      success: (data) ->
        location.href = '/'
      error: (jqXHR) ->
        $form.on 'submit', submitHandler
        json = jqXHR.responseJSON
        if json?
          if json.error
            $box = $('.flash-message-box')
            $box.empty()
            $box.append $('<div>').addClass('alert').addClass('alert-danger').text(json.error)
          if json.errors?
            for e in json.errors
              if (e.ValidationError?)
                for name, arr of e.ValidationError
                  $(".form-group:has(##{name})").addClass 'has-error'
    event.preventDefault()
  $form.on 'submit', submitHandler
