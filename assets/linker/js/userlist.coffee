generateUserlist = (query) ->
  user_id = $.cookie 'user_id'
  jQuery.ajax
    url: query
    success: (users) ->
      $list = $('#userlist')
      users.sort (a, b) -> a.createdAt - b.createdAt
      for user in users
        $a = $('<a>')
          .addClass('list-group-item hide-overflow')
          .attr('href', "/profile/#{user.id}")
          .data('user_id', user.id)
          .text(user.username + ' ')
        $a.append $('<a>').attr('href', '/userlist/ssb').addClass('btn btn-default btn-xs').text('64') if user.SSB
        $a.append $('<a>').attr('href', '/userlist/ssbm').addClass('btn btn-default btn-xs').text('DX') if user.SSBM
        $a.append $('<a>').attr('href', '/userlist/ssbb').addClass('btn btn-default btn-xs').text('X') if user.SSBB
        $a.append $('<a>').attr('href', '/userlist/ssb4').addClass('btn btn-default btn-xs').text('3DS / Wii U') if user.SSB4
        $a.append $('<small>').text(' ' + user.catchphrase) if user.catchphrase?
        if user_id?
          $a.append $('<button>')
            .attr('type', 'button')
            .addClass('btn btn-default btn-xs pull-right btn-unfollow')
            .text('フォロー解除')
            .hide()
          $a.append $('<button>')
            .attr('type', 'button')
            .addClass('btn btn-default btn-xs pull-right btn-follow')
            .text('フォロー')
            .on 'click', (event) ->
              jQuery.get "/follow/create",
                user_id: user_id
                follow_id: $(@).parent().data 'user_id'
              , (follow) =>
                $(@).hide()
                jQuery.get '/csrfToken', null, (csrf) =>
                  $(@).parent().find('.btn-unfollow').data('follow_id', follow.id).on 'click', (event) ->
                    jQuery.ajax "/follow/#{ $(@).data 'follow_id' }",
                      data: csrf
                      method: 'delete'
                      success: () =>
                        $(@).hide()
                        $(@).parent().find('.btn-follow').show()
                    return false
                  .show()
              return false
        $list.prepend $a

      if user_id?
        jQuery.ajax '/follow',
          data:
            user_id: user_id
          success: (follows) ->
            jQuery.get '/csrfToken', null, (csrf) ->
              for follow in follows
                $a = $("a[href=\"/profile/#{ follow.follow_id }\"]")
                $a.find('.btn-follow').hide()
                $a.find('.btn-unfollow').data('follow_id', follow.id).on 'click', (event) ->
                  jQuery.ajax "/follow/#{ $(@).data 'follow_id' }",
                    data: csrf
                    method: 'delete'
                    success: () =>
                      $(@).hide()
                      $(@).parent().find('.btn-follow').show()
                  return false
                .show()
          error: () ->
            $('.btn-follow, .btn-unfollow').hide()

    error: ->
      alert 'ユーザーデータを取得できません'
