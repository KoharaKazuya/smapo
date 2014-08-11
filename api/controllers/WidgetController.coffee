require 'date-utils'
_ = require 'underscore'
request = require 'request'
async = require 'async'
xml2json = require 'xml2json'
Twitter = require 'twit'

module.exports =

  blog: (req, res) ->
    widget req, res, [getHatenablogData, getFc2blogData], (e) -> e.time

  zusaar: (req, res) ->
    widget req, res, [getZusaarData], (e) -> e.time

  twitch: (req, res) ->
    widget req, res, [getTwitchData]

  twitter: (req, res) ->
    widget req, res, [getTwitterData], (e) -> e.time

  video: (req, res) ->
    widget req, res, [getNicovideoData, getYoutubeData], (e) -> e.time


widget = (req, res, getDatas, comparator) ->

  response = (users) ->
    funcs = _.map getDatas, (getData) ->
      (callback) ->
        getData users, callback
    async.parallel funcs, (err, results) ->
      return res.json err.text, err.status if err
      count = req.query.count
      count = 100 if not count? or count > 100
      data = _.flatten results
      data = _.sortBy data, comparator if comparator
      return res.json data[-count...]

  if req.params.id?
    if req.params.id is 'all'
      User.find {}, (err, users) ->
        if err
          console.error JSON.stringify err
          return res.json { error: 'Database error' }
        response users
    else
      User.findOne req.params.id, (err, user) ->
        if err
          console.error JSON.stringify err
          return res.json { error: 'Database error' }
        if user?
          response [user]
        else
          return res.json { error: 'user not found' }, 404
  else
    followingUsers req, res, (users) ->
      response users

getHatenablogData = (users, callback) ->
  users = _.filter users, (u) -> u.hatenablog? and u.hatenablog != ''
  queries = _.map users, (user) ->
    service: 'hatenablog'
    name: user.hatenablog
  ApiCache.findOrCreateEach ['service', 'name'], queries, (err, apis) ->
    if err
      console.error JSON.stringify err
      return callback { text: 'Database error', status: 500 }

    grouped = _.groupBy apis, (api) ->
      if api.res != undefined and (new Date()).getTime() - (new Date(api.updatedAt)).getTime() < 60 * 60 * 1000  # 1hour
        'caches'
      else
        'newRequests'
    caches = grouped.caches
    caches = [] unless caches?
    newRequests = grouped.newRequests
    newRequests = [] unless newRequests?

    # generate access function
    queries = _.map newRequests, (q) -> q
    funcs = _.map newRequests, (u) ->
      (cb) ->
        query = queries.pop()
        request
          url: "http://#{ query.name }.hatenablog.com/feed"
          timeout: 3000
        , (err, response, body) ->
          if err
            console.error JSON.stringify err
            return cb { text: 'Hatenablog feed request error', status: 500 }
          return cb null, null unless response.statusCode is 200
          json = xml2json.toJson body,
            object: true
            sanitize: false
          return cb null unless json.feed? and json.feed.entry?
          entries = json.feed.entry
          entries = [entries] unless entries instanceof Array
          cb null, _.map entries, (e) ->
            user = _.find users, (u) -> u.hatenablog is query.name
            return {
              user_id: user.id
              user_icon: user.icon
              title: e.title
              time: (new Date(e.published)).getTime()
              link: e.link.href
              summary: e.summary
            }

    # access all api in parallel
    async.parallel funcs, (err, results) ->
      return callback err if err
      # map entries by triming
      callback null, _.compact _.flatten results.concat _.map caches, (cache) -> cache.res
      # record in cache
      for cache in newRequests
        user = _.find users, (u) -> u.hatenablog is cache.name
        cache.res = _.filter (_.compact _.flatten results), (entry) -> entry.user_id is user.id
        cache.save (err) -> null

getFc2blogData = (users, callback) ->
  users = _.filter users, (u) -> u.fc2blog? and u.fc2blog != ''
  queries = _.map users, (user) ->
    service: 'fc2blog'
    name: user.fc2blog
  ApiCache.findOrCreateEach ['service', 'name'], queries, (err, apis) ->
    if err
      console.error JSON.stringify err
      return callback { text: 'Database error', status: 500 }

    grouped = _.groupBy apis, (api) ->
      if api.res != undefined and (new Date()).getTime() - (new Date(api.updatedAt)).getTime() < 60 * 60 * 1000  # 1hour
        'caches'
      else
        'newRequests'
    caches = grouped.caches
    caches = [] unless caches?
    newRequests = grouped.newRequests
    newRequests = [] unless newRequests?

    # generate access function
    queries = _.map newRequests, (q) -> q
    funcs = _.map newRequests, (u) ->
      (cb) ->
        query = queries.pop()
        request
          url: "http://#{ query.name }/?xml"
          timeout: 3000
        , (err, response, body) ->
          if err
            console.error JSON.stringify err
            return cb { text: 'FC2Blog feed request error', status: 500 }
          return cb null, null unless response.statusCode is 200
          json = xml2json.toJson body,
            object: true
            sanitize: false
          return cb null unless json['rdf:RDF']? and json['rdf:RDF'].item?
          entries = json['rdf:RDF'].item
          entries = [entries] unless entries instanceof Array
          cb null, _.map entries, (e) ->
            user = _.find users, (u) -> u.fc2blog is query.name
            return {
              user_id: user.id
              user_icon: user.icon
              title: e.title
              time: (new Date(e['dc:date'])).getTime()
              link: e.link
              summary: e.description
            }

    # access all api in parallel
    async.parallel funcs, (err, results) ->
      return callback err if err
      # map entries by triming
      callback null, _.compact _.flatten results.concat _.map caches, (cache) -> cache.res
      # record in cache
      for cache in newRequests
        user = _.find users, (u) -> u.fc2blog is cache.name
        cache.res = _.filter (_.compact _.flatten results), (entry) -> entry.user_id is user.id
        cache.save (err) -> null

getZusaarData = (users, callback) ->
  users = _.filter users, (u) -> u.zusaar? and u.zusaar != ''
  queries = _.map users, (user) ->
    service: 'zusaar'
    name: user.zusaar
  ApiCache.findOrCreateEach ['service', 'name'], queries, (err, apis) ->
    if err
      console.error JSON.stringify err
      return callback { text: 'Database error', status: 500 }

    grouped = _.groupBy apis, (api) ->
      if api.res != undefined and (new Date()).getTime() - (new Date(api.updatedAt)).getTime() < 10 * 60 * 1000  # 10min
        'caches'
      else
        'newRequests'
    caches = grouped.caches
    caches = [] unless caches?
    newRequests = grouped.newRequests
    newRequests = [] unless newRequests?

    returnData = (curEvents) ->
      callback null, curEvents.concat _.map caches, (cache) -> cache.res

    if newRequests.length is 0
      returnData []
    else
      # request all users event
      requestAndCallback = (offset, preEvents) ->
        today = Date.today()
        prevMonth = Date.today()
        prevMonth.addMonths -1
        nextMonth = Date.today()
        nextMonth.addMonths 1
        request
          url: "http://www.zusaar.com/api/event/?count=100&start=#{ offset+1 }&ym=#{ (mon.toFormat 'YYYYMM' for mon in [prevMonth, today, nextMonth]).join ',' }&owner_id=#{ (_.map newRequests, (r) -> r.name ).join ',' }"
          timeout: 3000
        , (err, response, body) ->
          if err
            console.error JSON.stringify err
            return callback { text: 'Zusaar API request error', status: 500 }

          json = JSON.parse(body)
          events = _.map json.event, (event) ->
            user = _.find users, (u) -> u.zusaar is event.owner_id
            return {
              user_id: user.id
              user_icon: user.icon
              title: event.title
              time: (new Date(event.started_at)).getTime()
              link: event.event_url
              summary: (event.description.replace /<.*?>/g, '').replace /&.*;/g, ''
            }
          curEvents = preEvents.concat events
          if json.results_returned is 100
            # recursive call for over 100 events data
            requestAndCallback offset + 100, curEvents
          else
            returnData curEvents
            # record in cache
            for cache in newRequests
              user = _.find users, (u) -> u.zusaar is cache.name
              cache.res = _.filter curEvents, (event) -> event.user_id is user.id
              cache.save (err) -> null
      requestAndCallback(0, [])

getTwitchData = (users, callback) ->
  users = _.filter users, (u) -> u.twitch? and u.twitch != ''
  queries = _.map users, (user) ->
    service: 'twitch'
    name: user.twitch
  ApiCache.findOrCreateEach ['service', 'name'], queries, (err, apis) ->
    if err
      console.error JSON.stringify err
      return callback { text: 'Database error', status: 500 }

    grouped = _.groupBy apis, (api) ->
      if api.res != undefined and (new Date()).getTime() - (new Date(api.updatedAt)).getTime() < 60 * 1000  # 60sec
        'caches'
      else
        'newRequests'
    caches = grouped.caches
    caches = [] unless caches?
    newRequests = grouped.newRequests
    newRequests = [] unless newRequests?

    returnData = (curStreams) ->
      allStreams = curStreams.concat _.compact _.map caches, (cache) -> cache.res
      callback null, allStreams

    if newRequests.length is 0
      returnData []
    else
      # request all users stream
      requestAndCallback = (offset, preStreams) ->
        request
          url: "https://api.twitch.tv/kraken/streams?limit=100&offset=#{ offset }&channel=#{ (_.map newRequests, (r) -> r.name ).join ',' }"
          timeout: 3000
        , (err, response, body) ->
          if err
            console.error JSON.stringify err
            return { text: 'Twitch API request error', status: 500 }

          streams = _.compact _.map JSON.parse(body).streams, (stream) ->
            return null unless stream? and stream.channel?
            user = _.find users, (u) -> u.twitch is stream.channel.name
            return {
              user_id: user.id
              user_icon: user.icon
              title: stream.channel.status
              game: stream.channel.game
              link: stream.channel.url
            }
          curStreams = preStreams.concat streams
          if streams.length is 100
            # recursive call for over 100 streams data
            requestAndCallback offset + 100, curStreams
          else
            returnData curStreams
            # record in cache
            for cache in newRequests
              user = _.find users, (u) -> u.twitch is cache.name
              stream = _.find curStreams, (stream) -> stream.user_id is user.id
              cache.res = if stream? then stream else null
              cache.save (err) -> null
      requestAndCallback(0, [])

getTwitterData = (users, callback) ->
  users = _.filter users, (u) -> u.twitter? and u.twitter != ''
  query =
    service: 'twitter'
    name: 'ssbportal_flash'
  ApiCache.findOrCreate query, query, (err, api) ->
    if err
      console.error JSON.stringify err
      return callback { text: 'Database error', status: 500 }

    returnData = (allTweets) ->
      callback null, _.filter allTweets, (t) -> t.user_id in _.map users, (u) -> u.id

    if api.res != undefined and (new Date()).getTime() - (new Date(api.updatedAt)).getTime() < 60 * 1000  # 60sec
      returnData api.res
    else
      twitter.get '/statuses/mentions_timeline', { count: 200 }, (err, tweets, response) ->
        if err
          console.error JSON.stringify err
          return callback { text: 'Twitter API error', status: 500 }

        User.find {}, (err, allUsers) ->
          if err
            console.error JSON.stringify err
            return callback { text: 'Database error', status: 500 }
          data = _.compact _.map tweets, (tweet) ->
            user = _.find allUsers, (u) -> u.twitter is tweet.user.screen_name
            return null unless user?
            return {
              user_id: user.id
              username: user.username
              time: (new Date(tweet.created_at)).getTime()
              message: tweet.text.replace /^@ssbportal_flash[ 　]*/, ''
              link: "https://twitter.com/#{ tweet.user.screen_name }/status/#{ tweet.id_str }"
            }

          returnData data

          # record in cache
          api.res = data
          api.save (err) -> null

getNicovideoData = (users, callback) ->
  users = _.filter users, (u) -> u.nicovideo? and u.nicovideo != ''
  queries = _.map users, (user) ->
    service: 'nicovideo'
    name: String user.nicovideo
  ApiCache.findOrCreateEach ['service', 'name'], queries, (err, apis) ->
    if err
      console.error JSON.stringify err
      return callback { text: 'Database error', status: 500 }

    grouped = _.groupBy apis, (api) ->
      if api.res != undefined and (new Date()).getTime() - (new Date(api.updatedAt)).getTime() < 60 * 60 * 1000  # 1hour
        'caches'
      else
        'newRequests'
    caches = grouped.caches
    caches = [] unless caches?
    newRequests = grouped.newRequests
    newRequests = [] unless newRequests?

    # generate access function
    queries = _.map newRequests, (q) -> q
    funcs = _.map newRequests, (u) ->
      (cb) ->
        query = queries.pop()
        request
          url: "http://www.nicovideo.jp/user/#{ query.name }/video?rss=atom"
          timeout: 3000
        , (err, response, body) ->
          if err
            console.error JSON.stringify err
            return cb { text: 'Nicovideo feed request error', status: 500 }
          return cb null, null unless response.statusCode is 200
          json = xml2json.toJson body,
            object: true
            sanitize: false
          return cb null unless json.feed? and json.feed.entry?
          entries = json.feed.entry
          entries = [entries] unless entries instanceof Array
          cb null, _.map entries, (e) ->
            user = _.find users, (u) -> parseInt(u.nicovideo, 10) is parseInt(query.name, 10)
            return {
              user_id: user.id
              user_icon: user.icon
              title: e.title
              time: (new Date(e.published)).getTime()
              link: e.link.href
              summary: e.content.$t.replace /^.*nico-description\">(.*?)<\/p>.*$/, (substr, m) -> m
            }

    # access all api in parallel
    async.parallel funcs, (err, results) ->
      return callback err if err
      # map entries by triming
      callback null, _.compact _.flatten results.concat _.map caches, (cache) -> cache.res
      # record in cache
      for cache in newRequests
        user = _.find users, (u) -> parseInt(u.nicovideo, 10) is parseInt(cache.name, 10)
        cache.res = _.filter (_.compact _.flatten results), (entry) -> entry.user_id is user.id
        cache.save (err) -> null

getYoutubeData = (users, callback) ->
  users = _.filter users, (u) -> u.youtube? and u.youtube != ''
  queries = _.map users, (user) ->
    service: 'youtube'
    name: user.youtube
  ApiCache.findOrCreateEach ['service', 'name'], queries, (err, apis) ->
    if err
      console.error JSON.stringify err
      return callback { text: 'Database error', status: 500 }

    grouped = _.groupBy apis, (api) ->
      if api.res != undefined and (new Date()).getTime() - (new Date(api.updatedAt)).getTime() < 60 * 60 * 1000  # 1hour
        'caches'
      else
        'newRequests'
    caches = grouped.caches
    caches = [] unless caches?
    newRequests = grouped.newRequests
    newRequests = [] unless newRequests?

    # generate access function
    queries = _.map newRequests, (q) -> q
    funcs = _.map newRequests, (u) ->
      (cb) ->
        query = queries.pop()
        request
          url: "http://gdata.youtube.com/feeds/api/users/#{ query.name }/uploads"
          timeout: 3000
        , (err, response, body) ->
          if err
            console.error JSON.stringify err
            return cb { text: 'YouTube feed request error', status: 500 }
          return cb null, null unless response.statusCode is 200
          json = xml2json.toJson body,
            object: true
            sanitize: false
          return cb null unless json.feed? and json.feed.entry?
          entries = json.feed.entry
          entries = [entries] unless entries instanceof Array
          cb null, _.map entries, (e) ->
            user = _.find users, (u) -> u.youtube is query.name
            return {
              user_id: user.id
              user_icon: user.icon
              title: e.title.$t
              time: (new Date(e.published)).getTime()
              link: (_.find e.link, (l) -> l.rel is 'alternate').href
              summary: e.content.$t
            }

    # access all api in parallel
    async.parallel funcs, (err, results) ->
      return callback err if err
      # map entries by triming
      callback null, _.compact _.flatten results.concat _.map caches, (cache) -> cache.res
      # record in cache
      for cache in newRequests
        user = _.find users, (u) -> u.youtube is cache.name
        cache.res = _.filter (_.compact _.flatten results), (entry) -> entry.user_id is user.id
        cache.save (err) -> null

followingUsers = (req, res, callback) ->
  return res.json { error: 'Must login' } unless req.session.user?
  Follow.find { user_id: req.session.user }, (err, follows) ->
    if err
      console.error JSON.stringify err
      return res.json { error: 'Database error' }, 500
    query = _.map follows, (f) -> f.follow_id
    User.where { id: query }, (err, users) ->
      if err
        console.error JSON.stringify err
        return res.json { error: 'Database error' }, 500
      callback(users)

twitter = new Twitter
  consumer_key: process.env.TWITTER_CONSUMER_KEY,
  consumer_secret: process.env.TWITTER_CONSUMER_SECRET,
  access_token: process.env.TWITTER_ACCESS_TOKEN,
  access_token_secret: process.env.TWITTER_ACCESS_TOKEN_SECRET
