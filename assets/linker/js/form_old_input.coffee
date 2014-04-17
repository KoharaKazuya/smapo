form_old_input = (name, old) ->
  $("[name=#{name}]").val old[name]
  $(":checkbox[name=#{name}]").attr 'checked', old[name]
