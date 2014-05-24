generateWidgetHatenablog = (user, count) ->
  url = '/widget/hatenablog'
  url += "/#{user}" if user?
  url += "?count=#{count}" if count?
  $loading = $('<div>').addClass('loading')
  $('#blog .panel-title').append $loading
  jQuery.get url, (entries) ->
    $ ->
      $loading.remove()
      $ul = $('#blog ul')
      for entry in entries
        $li = $('<li>')
        $li.append generateUserIcon entry
        date = new Date(entry.time)
        $li.append $('<a>').attr('href', entry.link).append(
          $('<h5>').text(' ' + entry.title).prepend($('<small>').text("#{date.getMonth() + 1}/#{date.getDate()}"))
          $('<p>').text(entry.summary)
        )
        $ul.prepend $li

generateWidgetZusaar = (user, count) ->
  url = '/widget/zusaar'
  url += "/#{user}" if user?
  url += "?count=#{count}" if count?
  $loading = $('<div>').addClass('loading')
  $('#event .panel-title').append $loading
  jQuery.get url, (entries) ->
    $ ->
      $loading.remove()
      $ul = $('#event ul')
      for entry in entries
        $li = $('<li>')
        $li.append generateUserIcon entry
        date = new Date(entry.time)
        $li.append $('<a>').attr('href', entry.link).append(
          $('<h5>').text(' ' + entry.title).prepend($('<small>').text("#{date.getMonth() + 1}/#{date.getDate()}"))
          $('<p>').text(entry.summary)
        )
        $ul.prepend $li

generateWidgetTwitch = (user, count) ->
  url = '/widget/twitch'
  url += "/#{user}" if user?
  url += "?count=#{count}" if count?
  $loading = $('<div>').addClass('loading')
  $('#live .panel-title').append $loading
  jQuery.get url, (entries) ->
    $ ->
      $loading.remove()
      $ul = $('#live ul')
      for entry in entries
        $li = $('<li>')
        $li.append generateUserIcon entry
        date = new Date(entry.time)
        $li.append $('<a>').attr('href', entry.link).append(
          $('<h5>').text(' ' + entry.title).prepend($('<small>').text(entry.game))
        )
        $ul.prepend $li

generateWidgetTwitter = (user, count) ->
  url = '/widget/twitter'
  url += "/#{user}" if user?
  url += "?count=#{count}" if count?
  $loading = $('<div>').addClass('loading')
  $('#flash .panel-title').append $loading
  jQuery.get url, (entries) ->
    $ ->
      $loading.remove()
      $ul = $('#flash ul')
      for entry in entries
        $li = $('<li>')

        date = new Date(entry.time)
        today = new Date
        timeDiff = (new Date).getTime() - (new Date(entry.time)).getTime()
        if timeDiff < 60 * 60 * 1000
          displayTime = Math.floor(timeDiff / (60*1000)) + ' 分前'
        else if timeDiff < 24 * 60 * 60 * 1000
          displayTime = Math.floor(timeDiff / (60*60*1000)) + ' 時間前'
        else
          displayTime = Math.floor(timeDiff / (24*60*60*1000)) + ' 日前'

        $h5 = $('<h5>').append($('<small>')
          .text(displayTime + ' ')
          .append($('<a>').attr('href', "/profile/#{entry.user_id}").text(entry.username + ' '))
        ).append($('<a>').text(entry.message).attr('href', entry.link))
        $ul.prepend $li.append($h5)

generateWidgetVideo = (user, count) ->
  url = '/widget/video'
  url += "/#{user}" if user?
  url += "?count=#{count}" if count?
  $loading = $('<div>').addClass('loading')
  $('#video .panel-title').append $loading
  jQuery.get url, (entries) ->
    $ ->
      $loading.remove()
      $ul = $('#video ul')
      for entry in entries
        $li = $('<li>')
        $li.append generateUserIcon entry
        date = new Date(entry.time)
        $li.append $('<a>').attr('href', entry.link).append(
          $('<h5>').text(' ' + entry.title).prepend($('<small>').text("#{date.getMonth() + 1}/#{date.getDate()}"))
          $('<p>').text(entry.summary)
        )
        $ul.prepend $li

generateUserIcon = (entry) ->
  $('<a>').append(
    $('<img>').addClass('user-icon').attr('src', if entry.user_icon? and entry.user_icon != '' then entry.user_icon else '/images/icon/404_smashball.png')
  ).attr('href', '/profile/' + entry.user_id).on
    mouseenter: ->
      loadProfile = (cb) =>
        $profile = $('<div>').addClass('mini-profile')
        $(@).parent().append $profile
        jQuery.get $(@).attr('href').replace(/^\/profile\//, '/user/'), (user) ->
          $profile.append $('<h5>').text(user.username + ' ').append $('<small>').text(user.catchphrase)
          $profile.append $('<p>').text(user.self_introduction)
          cb()
      showProfile = () =>
        $profile = $(@).parent().find '.mini-profile'
        $profile.prev().stop().animate
          maxHeight: 0
        , 'fast'
        $profile.stop().animate
          maxHeight: '74px'
        , 'fast'
      if $(@).parent().find('.mini-profile').size() > 0
        showProfile()
      else
        loadProfile showProfile
    mouseleave: ->
      $profile = $('.mini-profile')
      $profile.stop().animate
        maxHeight: 0
      , 'fast'
      $profile.prev().stop().animate
        maxHeight: '74px'
      , 'fast'
