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
      type: 'string'
      maxLength: 1000
    catchphrase:
      type: 'string'
      maxLength: 100
    SSB: 'boolean'
    SSBM: 'boolean'
    SSBB: 'boolean'
    SSB4: 'boolean'
    address:
      type: 'string'
      maxLength: 100
    # service
    hatenablog:
      type: 'string'
      maxLength: 32
    fc2blog:
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
    youtube:
      type: 'string'
      maxLength: 64
    toJSON: () ->
      obj = @.toObject()
      delete obj.password
      delete obj.email
      delete obj.updatedAt
      obj.createdAt = (new Date(obj.createdAt)).getTime()
      obj

  beforeCreate: (values, next) ->
    if values.password != values.password_confirmation
      return next
        ValidationError:
          password_confirmation: 'password confirmation is different'
    # remove invalid attributes
    removeInvalidAttributes values
    normalizeAttributes values
    # encode password
    bcrypt.hash values.password, 8, (err, hash) ->
      return next(err) if err
      values.password = hash
      next()

  beforeUpdate: (values, next) ->
    if values.password != values.password_confirmation
      return next
        ValidationError:
          password_confirmation: 'password confirmation is different'
    # remove not-updatable attributes
    delete values.username
    delete values.confirmed
    # email confirmation check
    values.confirmed = false if values.email?
    if values.confirmation_code?
      values.confirmed = true if bcrypt.compareSync values.email + sails.config.session.secret, values.confirmation_code

    removeInvalidAttributes values
    normalizeAttributes values
    # encode password
    if values.password?
      bcrypt.hash values.password, 8, (err, hash) ->
        return next(err) if err
        values.password = hash
        next()
    else
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
      'SSB'
      'SSBM'
      'SSBB'
      'SSB4'
      'address'
      'hatenablog'
      'fc2blog'
      'zusaar'
      'twitch'
      'twitter'
      'skype'
      'nicovideo'
      'youtube'
    ]

normalizeAttributes = (values) ->
  removeString = (exprs, str) ->
    for expr in exprs
      str = str.replace expr, ''
    return str
  attr = [
    'hatenablog'
    'fc2blog'
    'zusaar'
    'twitch'
    'twitter'
    'youtube'
  ]
  for k, v of values
    if k in attr
      values[k] = removeString [/^.*:/, /^\/+/, /[/?&=]+/g], v
