require 'date-utils'
_ = require 'underscore'
request = require 'request'
async = require 'async'
xml2json = require 'xml2json'
Twitter = require 'twit'

module.exports =

  hatenablog: (req, res) ->
    widget req, res, getHatenablogData

  zusaar: (req, res) ->
    widget req, res, getZusaarData

  twitch: (req, res) ->
    widget req, res, getTwitchData

  twitter: (req, res) ->
    widget req, res, getTwitterData


widget = (req, res, getData) ->

  response = (data) ->
    count = req.query.count
    count = 100 if not count? or count > 100
    return res.json data[-count...]

  if req.params.id?
    if req.params.id is 'all'
      User.find {}, (err, users) ->
        return res.json { error: 'Database error' } if err
        getData res, users, (data) -> response data
    else
      User.findOne req.params.id, (err, user) ->
        if user?
          getData res, [user], (data) -> response data
        else
          return res.json { error: 'user not found' }, 404
  else
    followingUsers req, res, (users) ->
      getData res, users, (data) -> response data

getHatenablogData = (res, users, callback) ->
  users = _.filter users, (u) -> u.hatenablog? and u.hatenablog != ''
  queries = _.map users, (user) ->
    service: 'hatenablog'
    id: user.hatenablog
  ApiCache.findOrCreateEach ['service', 'id'], queries, (err, apis) ->
    return res.json { error: 'Database error' }, 500 if err

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
      (callback) ->
        query = queries.pop()
        qStr = "http://#{ query.id }.hatenablog.com/feed"
        request qStr, (err, response, body) ->
          return callback err if err?
          return callback null, null unless response.statusCode is 200
          json = xml2json.toJson body,
            object: true
            sanitize: false
          return null unless json.feed? and json.feed.entry?
          entries = json.feed.entry
          entries = [entries] unless entries instanceof Array
          callback null, _.map entries, (e) ->
            user = _.find users, (u) -> u.hatenablog is query.id
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
      return res.json err if err
      # map entries by triming
      entries = _.compact _.flatten results.concat _.map caches, (cache) -> cache.res
      # sort entries and take [size]
      callback _.sortBy entries, (e) -> e.time
      # record in cache
      for cache in newRequests
        user = _.find users, (u) -> u.hatenablog is cache.id
        cache.res = _.filter (_.compact _.flatten results), (entry) -> entry.user_id is user.id
        cache.save (err) -> null

getZusaarData = (res, users, callback) ->
  users = _.filter users, (u) -> u.zusaar? and u.zusaar != ''
  queries = _.map users, (user) ->
    service: 'zusaar'
    id: user.zusaar
  ApiCache.findOrCreateEach ['service', 'id'], queries, (err, apis) ->
    return res.json { error: 'Database error' }, 500 if err

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
      allEvents = curEvents.concat _.flatten _.map caches, (cache) -> cache.res
      callback _.sortBy allEvents, (e) -> e.time

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
        qStr = "http://www.zusaar.com/api/event/?count=100&start=#{ offset+1 }&ym=#{ (mon.toFormat 'YYYYMM' for mon in [prevMonth, today, nextMonth]).join ',' }&owner_id=#{ (_.map newRequests, (r) -> r.id ).join ',' }"
        request qStr, (err, response, body) ->
          return res.json.err if err?

          json = JSON.parse(body)
          events = _.map json.event, (event) ->
            user = _.find users, (u) -> u.zusaar is event.owner_id
            return {
              user_id: user.id
              user_icon: user.icon
              title: event.title
              time: (new Date(event.started_at)).getTime()
              link: event.event_url
              summary: event.description
            }
          curEvents = preEvents.concat events
          if json.results_returned is 100
            # recursive call for over 100 events data
            requestAndCallback offset + 100, curEvents
          else
            returnData curEvents
            # record in cache
            for cache in newRequests
              user = _.find users, (u) -> u.zusaar is cache.id
              cache.res = _.filter curEvents, (event) -> event.user_id is user.id
              cache.save (err) -> null
      requestAndCallback(0, [])

getTwitchData = (res, users, callback) ->
  users = _.filter users, (u) -> u.twitch? and u.twitch != ''
  queries = _.map users, (user) ->
    service: 'twitch'
    id: user.twitch
  ApiCache.findOrCreateEach ['service', 'id'], queries, (err, apis) ->
    return res.json { error: 'Database error' }, 500 if err

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
      callback allStreams

    if newRequests.length is 0
      returnData []
    else
      # request all users stream
      requestAndCallback = (offset, preStreams) ->
        qStr = "https://api.twitch.tv/kraken/streams?limit=100&offset=#{ offset }&channel=#{ (_.map newRequests, (r) -> r.id ).join ',' }"
        request qStr, (err, response, body) ->
          return res.json.err if err?

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
              user = _.find users, (u) -> u.twitch is cache.id
              stream = _.find curStreams, (stream) -> stream.user_id is user.id
              cache.res = if stream? then stream else null
              cache.save (err) -> null
      requestAndCallback(0, [])

getTwitterData = (res, users, callback) ->
  users = _.filter users, (u) -> u.twitter? and u.twitter != ''
  query =
    service: 'twitter'
    id: 'ssbportal_flash'
  ApiCache.findOrCreate query, query, (err, api) ->
    return res.json { error: 'Database error' }, 500 if err

    returnData = (allTweets) ->
      follow_flashes = _.filter allTweets, (t) -> t.user_id in _.map users, (u) -> u.id
      callback _.sortBy follow_flashes, (f) -> f.time

    if api.res != undefined and (new Date()).getTime() - (new Date(api.updatedAt)).getTime() < 60 * 1000  # 60sec
      returnData api.res
    else
      twitter.get '/statuses/mentions_timeline', { count: 200 }, (err, tweets, response) ->
        return res.json { error: 'Twitter error' }, 500 if err

        User.find {}, (err, allUsers) ->
          return res.json { error: 'Database error' }, 500 if err
          data = _.compact _.map tweets, (tweet) ->
            user = _.find allUsers, (u) -> u.twitter is tweet.user.screen_name
            return null unless user?
            return {
              user_id: user.id
              username: user.username
              time: (new Date(tweet.created_at)).getTime()
              message: tweet.text.replace /^@ssbportal_flash /, ''
              link: "https://twitter.com/#{ tweet.user.screen_name }/status/#{ tweet.id_str }"
            }

          returnData data

          # record in cache
          api.res = data
          api.save (err) -> null

followingUsers = (req, res, callback) ->
  return res.json { error: 'Must login' } unless req.session.user?
  Follow.find { user_id: req.session.user }, (err, follows) ->
    return res.json { error: 'Database error' }, 500 if err
    query = _.map follows, (f) -> f.follow_id
    User.where { id: query }, (err, users) ->
      return res.json { error: 'Database error' }, 500 if err
      callback(users)

twitter = new Twitter
  consumer_key: process.env.TWITTER_CONSUMER_KEY,
  consumer_secret: process.env.TWITTER_CONSUMER_SECRET,
  access_token: process.env.TWITTER_ACCESS_TOKEN,
  access_token_secret: process.env.TWITTER_ACCESS_TOKEN_SECRET
