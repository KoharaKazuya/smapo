module.exports =

  attributes:
    user_id:
      type: 'integer'
      required: true
    follow_id:
      type: 'integer'
      required: true

  beforeCreate: (values, next) ->
    Follow.findOne
      user_id: values.user_id
      follow_id: values.follow_id
    .done (err, follow) ->
      return next(err) if err
      return next('Following already') if follow?
      next()
