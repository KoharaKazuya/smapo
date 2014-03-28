jQuery.ajax '/user/links',
  success: (data) ->
    jQuery ->
      $ul = $ 'header.navbar #navbar-items ul'
      # generate help links
      $link_hatenablog = li_a('/help/hatenablog', 'はてなブログ', '日記')
      $link_zusaar = li_a('/help/zusaar', 'Zusaar', 'オフ会')
      $link_twitch = li_a('/help/twitch', 'Twitch', '生放送')
      $link_twitter = li_a('/help/twitter', 'Twitter', '一行宣伝')
      # generate service links
      $service_hatenablog = $link_hatenablog.clone()
      $service_zusaar = $link_zusaar.clone()
      $service_twitch = $link_twitch.clone()
      $service_twitter = $link_twitter.clone()
      $service_hatenablog.find('a').attr('href', "//#{data.hatenablog}.hatenablog.com") if data.hatenablog
      $service_zusaar.find('a').attr('href', "//www.zusaar.com/user/#{data.zusaar}") if data.zusaar
      $service_twitch.find('a').attr('href', "//ja.twitch.tv/#{data.twitch}") if data.twitch
      $service_twitter.find('a').attr('href', "//twitter.com/intent/tweet?text=%40ssbportal_flash%20") if data.twitter

      $services = $('<li class="dropdown">')
        .append($('<a class="dropdown-toggle" href="#" data-toggle="dropdown">')
          .text(' 連携サービス ')
          .prepend($('<span class="glyphicon glyphicon-cloud">'))
          .append($('<b class="caret">')))
        .append $('<ul class="dropdown-menu">')
          .append($service_hatenablog)
          .append($service_zusaar)
          .append($service_twitch)
          .append($service_twitter)

      $profile = $('<li>').append $("<a href=\"/user/#{ data.id }\">")
        .text(' プロフィール')
        .prepend($ '<span class="glyphicon glyphicon-user">')

      $setting = $('<li class="dropdown">')
        .append($('<a class="dropdown-toggle" href="#" data-toggle="dropdown">')
          .text(' 設定 ')
          .prepend($('<span class="glyphicon glyphicon-cog">'))
          .append($('<b class="caret">')))
        .append $('<ul class="dropdown-menu">')
          .append(li_a '/setting/profile', 'プロフィール')
          .append(li_a '/setting/service', '連携サービス')
          .append(li_a '/setting/account', 'アカウント')

      $help = $('<li class="dropdown">')
        .append($('<a class="dropdown-toggle" href="#" data-toggle="dropdown">')
          .text(' ヘルプ ')
          .prepend($('<span class="glyphicon glyphicon-question-sign">'))
          .append($('<b class="caret">')))
        .append $('<ul class="dropdown-menu">')
          .append(li_a 'help/usage', 'このサイトについて')
          .append($ '<li class="divider">')
          .append($link_hatenablog)
          .append($link_zusaar)
          .append($link_twitch)
          .append($link_twitter)

      $logout = $('<li>').append $("<a href=\"/user/signout\">")
        .text(' ログアウト')
        .prepend($ '<span class="glyphicon glyphicon-log-out">')

      # refresh header list
      $ul.empty()
      $ul
        .append($services)
        .append($profile)
        .append($setting)
        .append($help)
        .append($logout)

li_a = (url, text, nav) ->
  $li = $('<li>')
  $a = $("<a href=\"#{url}\">")
  if nav?
    $a.append($('<small>').text(nav)).append(" #{text}")
  else
    $a.text text
  $li.append $a
