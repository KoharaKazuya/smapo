module.exports = (req, res, next) ->

  if "#{req.session.user}" == req.params.id
    next()
  else
    res.forbidden 'You are not permitted to perform this action.'
