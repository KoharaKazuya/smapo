module.exports =

  attributes:
    user_id:
      type: 'string'
      required: true
      maxLength: 32
    follow_id:
      type: 'string'
      required: true
      maxLength: 32

  beforeCreate: (values, next) ->
    Follow.findOne
      user_id: values.user_id
      follow_id: values.follow_id
    .done (err, follow) ->
      return next(err) if err
      return next('Following already') if follow?
      next()
