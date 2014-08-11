module.exports =

  attributes:
    user_id:
      type: 'string'
      required: true
      maxLength: 32
    message:
      type: 'string'
      maxLength: 10000
