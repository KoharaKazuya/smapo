module.exports = (req, res, next) ->

  if req.params.id?
    id = parseInt req.params.id
    Follow.findOne(id).done (err, follow) ->
      return next(err) if err
      return next() unless follow?

      if "#{ req.session.user }" is "#{ follow.user_id }"
        next()
      else
        res.forbidden 'You are not owner of this follow'

  else
    if "#{req.session.user}" is req.query.user_id
      next()
    else
      res.forbidden 'Cannot treat with other\'s follow'
