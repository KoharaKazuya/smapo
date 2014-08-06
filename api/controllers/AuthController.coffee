bcrypt = require 'bcrypt'
sendgrid = (require 'sendgrid')(process.env.SENDGRID_USERNAME, process.env.SENDGRID_PASSWORD)

module.exports =

  login: (req, res) ->
    User.find().where
      or: [{ email: req.body.account }, { username: req.body.account }]
    .limit(1).done (err, users) ->
      return res.json { error: 'Database error' }, 500 if err

      user = users[0]
      if user?
        if user.confirmed
          bcrypt.compare req.body.password, user.password, (err, match) ->
            return res.json { error: 'Server error' }, 500 if err

            if match
              req.session.user = user.id
              return res.json user
            else
              req.session.user = null
              return res.json
                errors: [
                  ValidationError:
                    password: 'Invalid password'
                ]
              , 400
        else
          return res.json { error: 'have not confirmed yet' }, 400

      else
        return res.json
          errors: [
            ValidationError:
              account: 'User not found'
          ]
        , 404

  logout: (req, res) ->
    req.session.user = null
    res.json { success: 'logout' }

  confirm: (req, res) ->
    User.update
      email: decodeURIComponent req.query.email
    ,
      email: decodeURIComponent req.query.email
      confirmation_code: decodeURIComponent req.query.confirmation_code
    , (err, users) ->
      return res.json { error: error }, 400 if err
      if users[0]?
        if users[0].confirmed
          return res.redirect '/auth/signin'
        else
          return res.json { error: 'wrong confirmation code' }, 400
      else
        return res.json { error: 'user not found' }, 400

  confirmationmail: (req, res) ->
    User.findOne { email: decodeURIComponent req.query.email }, (err, user) ->
      return res.json { error: 'Database error' }, 500 if err

      if user?
        return res.json { error: 'confirmed already' }, 400 if user.confirmed

        bcrypt.hash user.email + sails.config.session.secret, 8, (err, hash) ->
          return res.json { error: 'bcrypt error' }, 500 if err

          confirmationUrl = "http://ssbp.info/auth/confirm?email=#{ encodeURIComponent user.email }&confirmation_code=#{ encodeURIComponent hash }"
          sendgrid.send
            to: user.email
            from: 'noreply@ssbp.info'
            fromname: sails.config.appName
            subject: 'アカウントの確認'
            html: """
            <p>こんにちは、 #{ user.username } さん！</p>
            <p><a href="http://ssbp.info">スマブラポータル</a>です。</p>
            <p>#{ user.username } さんのアカウントを作成しました。<br>
            ログインするためには、以下の URL をクリックしてアカウントを有効化してください。</p>
            <p><a href="#{ confirmationUrl }">#{ confirmationUrl }</a></p>
            """
          , (err, json) ->
            return res.json { error: 'mail error' }, 500 if err
            return res.json json
      else
        return res.json { error: 'user not found' }, 404

  forgotpassword: (req, res) ->
    User.findOne { email: req.query.email }, (err, user) ->
      return res.json { error: 'Database error' }, 500 if err

      if user?
        bcrypt.hash user.password + sails.config.session.secret, 8, (err, hash) ->
          return res.json { error: 'bcrypt error' }, 500 if err

          resetUrl = "http://ssbp.info/support/resetpassword"
          sendgrid.send
            to: user.email
            from: 'noreply@ssbp.info'
            fromname: sails.config.appName
            subject: 'パスワードのリセット'
            html: """
            <p>こんにちは、 #{ user.username } さん！</p>
            <p><a href="http://ssbp.info">スマブラポータル</a>です。</p>
            <p>#{ user.username } さんのパスワードのリセットが要求されました。<br>
            リセットするためには、以下の URL をクリックしてください。<br>
            次のページから確認コードに <strong><code>#{ hash }</code></strong> を入力して下さい。</p>
            <p><a href="#{ resetUrl }">#{ resetUrl }</a></p>
            """
          , (err, json) ->
            return res.json { error: 'mail error' }, 500 if err
            return res.json json
      else
        return res.json { error: 'user not found' }, 404
