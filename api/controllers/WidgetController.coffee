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
