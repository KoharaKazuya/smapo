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
    selfIntroduction:
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

  beforeCreate: (values, next) ->
    bcrypt.hash values.password, 8, (err, hash) ->
      return next(err) if err
      values.password = hash
      next()
