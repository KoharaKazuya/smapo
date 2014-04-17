generateUserlist = (query) ->
  jQuery.ajax
    url: query
    success: (users) ->
      $list = $('#userlist')
      users.sort (a, b) ->
        new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()
      for user in users
        $a = $('<a>')
          .addClass('list-group-item hide-overflow')
          .attr('href', "/profile/#{user.id}")
          .text(user.username + ' ')
        $a.append $('<a>').attr('href', '/userlist/ssb').addClass('btn btn-default btn-xs').text('64') if user.SSB
        $a.append $('<a>').attr('href', '/userlist/ssbm').addClass('btn btn-default btn-xs').text('DX') if user.SSBM
        $a.append $('<a>').attr('href', '/userlist/ssbb').addClass('btn btn-default btn-xs').text('X') if user.SSBB
        $a.append $('<a>').attr('href', '/userlist/ssb4').addClass('btn btn-default btn-xs').text('3DS / Wii U') if user.SSB4
        $a.append $('<small>').text(' ' + user.catchphrase) if user.catchphrase?
        $list.prepend $a
    error: ->
      alert 'ユーザーデータを取得できません'
