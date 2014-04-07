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
    externalApi req, res, 'zusaar', 'http://www.zusaar.com/api/event/?user_id=___id___&count=5', 5, (body) ->
      json = JSON.parse body
      _.map json.event, (e) ->
        return {
          title: e.title
          time: (new Date(e.started_at)).getTime()
          link: e.url
          summary: e.description
        }

  twitch: (req, res) ->
    followingUsers req, res, (users) ->
      getTwitchData res, users, (data) ->
        res.json data


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
    console.log "cache hit: #{caches.length}"
    console.log "new requests: #{newRequests.length}"
    # generate queries for each 100 users
    queries = _.map [0..((newRequests.length-1)/100)], (index) ->
      # pop 100 users
      requests = newRequests[0...100]
      newRequests = newRequests[100...]
      (callback) ->
        qStr = 'https://api.twitch.tv/kraken/streams?limit=100&channel=' + (_.map requests, (r) -> r.id ).join ','
        request qStr, (err, response, body) ->
          return callback err if err?
          return callback null, null unless response.statusCode is 200
          streams = JSON.parse(body).streams
          # record in cache
          for stream in streams
            cache = _.find apis, (api) -> (api.id is stream.channel.name)
            if cache?
              cache.res = JSON.stringify stream
              cache.save (err) -> null
          callback null, streams
    async.parallel queries, (err, results) ->
      return res.json err if err
      streams = (_.compact _.flatten results).concat _.map caches, (cache) -> JSON.parse cache.res
      callback _.compact _.map streams, (stream) ->
        return null unless stream? and stream.channel?
        return {
          title: stream.channel.status
          game: stream.channel.game
          link: stream.channel.url
        }

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
