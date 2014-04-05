_ = require 'underscore'
request = require 'request'
async = require 'async'
xml2json = require 'xml2json'

module.exports =

  hatenablog: (req, res) ->
    _existFollowUsers req, res, (users) ->
      # generate access function
      users = _.filter users, (u) ->
        u.hatenablog? and u.hatenablog != ''
      funcs = _.map users, (u) ->
        (callback) ->
          user = users.pop()
          request "http://#{user.hatenablog}.hatenablog.com/feed", (err, response, body) ->
            return callback err if err?
            return callback null, null unless response.statusCode is 200
            callback null, xml2json.toJson(body, { object: true, sanitize: false }).feed.entry

      # access all api in parallel
      async.parallel funcs, (err, results) ->
        return res.json err if err
        # map entries by triming
        entries = []
        for entry in Array.prototype.concat.apply [], results
          if entry?
            entries.push
              title: entry.title
              time: (new Date(entry.published)).getTime()
              link: entry.link.href
              summary: entry.summary
        # sort entries and head 5
        entries.sort (a, b) ->
          a.time - b.time
        entries = entries[0..5]
        res.json entries

_existFollowUsers = (req, res, fn) ->
  return res.json { error: 'Must login' } unless req.session.user?
  Follow.find { user_id: req.session.user }, (err, follows) ->
    res.json { error: 'Database error' }, 500 if err
    query = []
    for follow in follows
      query.push
        id: follow.follow_id
    User.find { 'or': query }, (err, users) ->
      return req.json { error: 'Database error' }, 500 if err
      fn users
