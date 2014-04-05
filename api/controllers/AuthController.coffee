bcrypt = require 'bcrypt'

module.exports =

  login: (req, res) ->
    User.find().where
      or: [{ email: req.body.account }, { username: req.body.account }]
    .limit(1).done (err, users) ->
      res.json { error: 'Database error' }, 500 if err

      user = users[0]
      if user?
        bcrypt.compare req.body.password, user.password, (err, match) ->
          res.json { error: 'Server error' }, 500 if err

          if match
            req.session.user = user.id
            res.cookie 'user_id', user.id
            res.json user
          else
            req.session.user = null
            res.json
              errors: [
                ValidationError:
                  password: 'Invalid password'
              ]
            , 400

      else
        res.json
          errors: [
            ValidationError:
              account: 'User not found'
          ]
        , 404

  logout: (req, res) ->
    req.session.user = null
    res.clearCookie 'user_id'
    res.json { success: 'logout' }
