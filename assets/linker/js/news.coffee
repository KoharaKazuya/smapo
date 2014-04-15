generateWidgetHatenablog = (count) ->
  url = '/widget/hatenablog'
  url += "?count=#{count}" if count?
  jQuery.get url, (entries) ->
    $ ->
      $ul = $('#blog ul')
      for entry in entries
        $li = $('<li>')
        $li.append $('<a>').append($('<img>').addClass('user-icon').attr('src', if entry.user_icon? and entry.user_icon != '' then entry.user_icon else '/images/icon/404_smashball.png')).attr('href', '/profile/' + entry.user_id)
        date = new Date(entry.time)
        $li.append $('<a>').attr('href', entry.link).append(
          $('<h5>').text(' ' + entry.title).prepend($('<small>').text("#{date.getMonth() + 1}/#{date.getDate()}"))
          $('<p>').text(entry.summary)
        )
        $ul.prepend $li

generateWidgetZusaar = (count) ->
  url = '/widget/zusaar'
  url += "?count=#{count}" if count?
  jQuery.get url, (entries) ->
    $ ->
      $ul = $('#event ul')
      for entry in entries
        $li = $('<li>')
        $li.append $('<a>').append($('<img>').addClass('user-icon').attr('src', if entry.user_icon? and entry.user_icon != '' then entry.user_icon else '/images/icon/404_smashball.png')).attr('href', '/profile/' + entry.user_id)
        date = new Date(entry.time)
        $li.append $('<a>').attr('href', entry.link).append(
          $('<h5>').text(' ' + entry.title).prepend($('<small>').text("#{date.getMonth() + 1}/#{date.getDate()}"))
          $('<p>').text(entry.summary)
        )
        $ul.prepend $li

generateWidgetTwitch = (count) ->
  url = '/widget/twitch'
  url += "?count=#{count}" if count?
  jQuery.get url, (entries) ->
    $ ->
      $ul = $('#live ul')
      for entry in entries
        $li = $('<li>')
        $li.append $('<a>').append($('<img>').addClass('user-icon').attr('src', if entry.user_icon? and entry.user_icon != '' then entry.user_icon else '/images/icon/404_smashball.png')).attr('href', '/profile/' + entry.user_id)
        date = new Date(entry.time)
        $li.append $('<a>').attr('href', entry.link).append(
          $('<h5>').text(' ' + entry.title).prepend($('<small>').text(entry.game))
        )
        $ul.prepend $li

generateWidgetTwitter = (count) ->
  url = '/widget/twitter'
  url += "?count=#{count}" if count?
  jQuery.get url, (entries) ->
    $ ->
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
