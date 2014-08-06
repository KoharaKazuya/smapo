bcrypt = require 'bcrypt'

module.exports =

  me: (req, res) ->
    User.findOne req.session.user, (err, user) ->
      return res.json { error: 'user not found' }, 500 if err
      return res.json user

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

  resetpassword: (req, res) ->
    User.findOne { email: req.query.email }, (err, user) ->
      return res.json { error: 'Database error' }, 500 if err
      return res.json { error: 'user not found' }, 404 unless user?

      bcrypt.compare user.password + sails.config.session.secret, (decodeURIComponent req.query.confirmation_code), (err, match) ->
        return res.json { error: 'bcrypt error' }, 500 if err

        user.password = req.query.password
        user.password_confirmation = req.query.password_confirmation
        delete user.email   # to prevent from resetting cofirmed field
        user.save (err) ->
          return res.json { errors: [err] } if err
          return res.json { success: 'reset password' }
