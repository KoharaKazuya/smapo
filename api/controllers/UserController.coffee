###
UserController

@module      :: Controller
@description    :: A set of functions called `actions`.

Actions contain code telling Sails how to respond to a certain type of request.
(i.e. do stuff, then send some JSON, show an HTML page, or redirect to another URL)

You can configure the blueprint URLs which trigger these actions (`config/controllers.js`)
and/or override them with custom routes (`config/routes.js`)

NOTE: The code you write here supports both HTTP and Socket.io automatically.

@docs        :: http://sailsjs.org/#!documentation/controllers
###

bcrypt = require 'bcrypt'

module.exports =

  ###
  Overrides for the settings in `config/controllers.js`
  (specific to UserController)
  ###
  _config: {}

  login: (req, res) ->
    User.find().where
      or: [{ email: req.body.account }, { username: req.body.account }]
    .limit(1).done (err, users) ->
      res.json { error: 'Database error' }, 500 if err

      user = users[0]
      if user?
        bcrypt.compare req.body.password, user.password, (err, match) ->
          res.json { error: 'Server error' }, 500 if err

          if match?
            req.session.user = user.id
            res.json user
          else
            req.session.user = null
            res.json { error: 'Invalid password' }, 400

      else
        res.json { error: 'User not found' }, 404

  logout: (req, res) ->
    req.session.user = null
    res.json { success: 'logout' }

  links: (req, res) ->
    if req.session.user?
      User.findOne(req.session.user).done (err, user) ->
        res.json { error: 'Database error' }, 500 if err
        res.json
          id: user.id
          hatenablog: user.hatenablog
          zusaar: user.zusaar
          twitch: user.twitch
          twitter: user.twitter
    else
      res.json { error: 'Only for authenticated user' }, 400
