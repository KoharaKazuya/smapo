module.exports =
  search: (req, res) ->
    query = req.query
    # delete invalid search query
    for k, v of query
      delete query[k] unless k in [
        'username'
        'self_introduction'
        'catchphrase'
      ]
    User.find(query).done (err, users) ->
      res.json { error: 'Database error' }, 500 if err
      res.json users
