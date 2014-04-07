_ = require 'underscore'
request = require 'request'
async = require 'async'
xml2json = require 'xml2json'

module.exports =

  hatenablog: (req, res) ->
    externalApi req, res, 'hatenablog', 'http://___id___.hatenablog.com/feed', 5, (body) ->
      json = xml2json.toJson body,
        object: true
        sanitize: false
      return null unless json.feed? and json.feed.entry?
      entries = json.feed.entry
      entries = [entries] unless entries instanceof Array
      _.map entries, (e) ->
        return {
          title: e.title
          time: (new Date(e.published)).getTime()
          link: e.link.href
          summary: e.summary
        }

  zusaar: (req, res) ->
    followingUsers req, res, (users) ->
      getZusaarData res, users, (data) ->
        res.json data

  twitch: (req, res) ->
    followingUsers req, res, (users) ->
      getTwitchData res, users, (data) ->
        res.json data


getZusaarData = (res, users, callback) ->
  ids = _.map users, (u) -> u.zusaar
  ids = _.filter ids, (id) -> id? and id != ''
  queries = _.map ids, (id) ->
    service: 'zusaar'
    id: id
  ApiCache.findOrCreateEach ['service', 'id'], queries, (err, apis) ->
    return res.json { error: 'Database error' }, 500 if err

    grouped = _.groupBy apis, (api) ->
      if api.res? and (new Date()).getTime() - (new Date(api.updatedAt)).getTime() < 10 * 60 * 1000  # 10min
        'caches'
      else
        'newRequests'
    caches = grouped.caches
    caches = [] unless caches?
    newRequests = grouped.newRequests
    newRequests = [] unless newRequests?

    returnData = (curEvents) ->
      allEvents = curEvents.concat _.flatten _.map caches, (cache) -> JSON.parse cache.res
      callback _.map allEvents, (event) ->
        return {
          title: event.title
          time: event.started_at
          link: event.event_url
          summary: event.description
        }

    if newRequests.length is 0
      returnData []
    else
      # request all users event
      requestAndCallback = (offset, preEvents) ->
        qStr = "http://www.zusaar.com/api/event/?count=100&start=#{ offset+1 }&owner_id=#{ (_.map newRequests, (r) -> r.id ).join ',' }"
        console.log "new request!: #{qStr}"
        request qStr, (err, response, body) ->
          return res.json.err if err?

          json = JSON.parse(body)
          events = json.event
          curEvents = preEvents.concat events
          if json.results_returned is 100
            # recursive call for over 100 events data
            requestAndCallback offset + 100, curEvents
          else
            returnData curEvents
            # record in cache
            for owner_id, events of _.groupBy(curEvents, (event) -> event.owner_id)
              cache = _.find apis, (api) -> (api.id is owner_id)
              if cache?
                cache.res = JSON.stringify events
                cache.save (err) -> null
      requestAndCallback(0, [])

getTwitchData = (res, users, callback) ->
  ids = _.map users, (u) -> u.twitch
  ids = _.filter ids, (id) -> id? and id != ''
  queries = _.map ids, (id) ->
    service: 'twitch'
    id: id
  ApiCache.findOrCreateEach ['service', 'id'], queries, (err, apis) ->
    return res.json { error: 'Database error' }, 500 if err

    grouped = _.groupBy apis, (api) ->
      if api.res? and (new Date()).getTime() - (new Date(api.updatedAt)).getTime() < 60 * 1000  # 60sec
        'caches'
      else
        'newRequests'
    caches = grouped.caches
    caches = [] unless caches?
    newRequests = grouped.newRequests
    newRequests = [] unless newRequests?

    returnData = (curStreams) ->
      allStreams = curStreams.concat _.map caches, (cache) -> JSON.parse cache.res
      callback _.compact _.map allStreams, (stream) ->
        return null unless stream? and stream.channel?
        return {
          title: stream.channel.status
          game: stream.channel.game
          link: stream.channel.url
        }

    if newRequests.length is 0
      returnData []
    else
      # request all users stream
      requestAndCallback = (offset, preStreams) ->
        qStr = "https://api.twitch.tv/kraken/streams?limit=100&offset=#{ offset }&channel=#{ (_.map newRequests, (r) -> r.id ).join ',' }"
        console.log "new request!: #{qStr}"
        request qStr, (err, response, body) ->
          return res.json.err if err?

          streams = JSON.parse(body).streams
          curStreams = preStreams.concat streams
          if streams.length is 100
            # recursive call for over 100 streams data
            requestAndCallback offset + 100, curStreams
          else
            returnData curStreams
            # record in cache
            for cache in apis
              stream = _.find curStreams, (stream) -> cache.id is stream.channel.name
              cache.res = JSON.stringify(if stream? then stream else {})
              cache.save (err) -> null
      requestAndCallback(0, [])

followingUsers = (req, res, callback) ->
  return res.json { error: 'Must login' } unless req.session.user?
  Follow.find { user_id: req.session.user }, (err, follows) ->
    res.json { error: 'Database error' }, 500 if err
    query = []
    for follow in follows
      query.push
        id: follow.follow_id
    User.find { 'or': query }, (err, users) ->
      return req.json { error: 'Database error' }, 500 if err
      callback(users)

externalApi = (req, res, service, url, size, body2Entry) ->
  return res.json { error: 'Must login' } unless req.session.user?
  Follow.find { user_id: req.session.user }, (err, follows) ->
    res.json { error: 'Database error' }, 500 if err
    query = []
    for follow in follows
      query.push
        id: follow.follow_id
    User.find { 'or': query }, (err, users) ->
      return req.json { error: 'Database error' }, 500 if err

      # generate access function
      users = _.filter users, (u) ->
        u[service]? and u[service] != ''
      funcs = _.map users, (u) ->
        (callback) ->
          user = users.pop()
          request url.replace(/___id___/, user[service]), (err, response, body) ->
            return callback err if err?
            return callback null, null unless response.statusCode is 200
            callback null, body2Entry(body)

      # access all api in parallel
      async.parallel funcs, (err, results) ->
        return res.json err if err
        # map entries by triming
        entries = _.compact _.flatten results
        # sort entries and take [size]
        entries.sort (a, b) ->
          b.time - a.time
        res.json entries[0..size].reverse()
