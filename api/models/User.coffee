###
User

@module      :: Model
@description :: A short summary of how this model works and what it represents.
@docs        :: http://sailsjs.org/#!documentation/models
###

bcrypt = require 'bcrypt'

module.exports =

  attributes:
    # account
    username:
      type: 'string'
      required: true
      unique: true
      maxLength: 32
    email:
      type: 'email'
      required: true
      unique: true
    password:
      type: 'string'
      required: true
      minLength: 6
      maxLength: 32
    confirmed:
      type: 'boolean'
      defaultsTo: false
    # profile
    self_introduction:
      type: 'text'
      maxLength: 10000
    icon:
      type: 'binary'
    catchphrase:
      type: 'string'
      maxLength: 100
    # service
    hatenablog:
      type: 'string'
      maxLength: 32
    zusaar:
      type: 'string'
      maxLength: 64
    twitch:
      type: 'string'
      maxLength: 32
    twitter:
      type: 'string'
      maxLength: 16
    skype:
      type: 'string'
      maxLength: 64
    nicovideo:
      type: 'integer'
      min: 0
      defaultsTo: 0
    toJSON: () ->
      obj = @.toObject()
      delete obj.password
      obj

  beforeCreate: (values, next) ->
    if values.password != values.password_confirmation
      return next
        ValidationError:
          password_confirmation: 'password confirmation is different'
    # remove invalid attributes
    removeInvalidAttributes values
    # encode password
    bcrypt.hash values.password, 8, (err, hash) ->
      return next(err) if err
      values.password = hash
      next()

  beforeUpdate: (values, next) ->
    removeInvalidAttributes values
    next()

removeInvalidAttributes = (values) ->
  for k, v of values
    delete values[k] unless k in [
      'username'
      'email'
      'password'
      'confirmed'
      'self_introduction'
      'icon'
      'catchphrase'
      'hatenablog'
      'zusaar'
      'twitch'
      'twitter'
      'skype'
      'nicovideo'
    ]
