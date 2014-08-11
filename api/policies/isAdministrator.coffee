module.exports = (req, res, next) ->

  User.find({id: req.session.user}).limit(1).done (err, users) ->
    return next(err) if err

    user = users[0]
    admins = JSON.parse process.env.ADMINS
    if user? and (user.username in admins)
      next()
    else
      res.forbidden 'You are not permitted to perform this action.'
