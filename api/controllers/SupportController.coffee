sendgrid = (require 'sendgrid')(process.env.SENDGRID_USERNAME, process.env.SENDGRID_PASSWORD)

module.exports =

  reportbug: (req, res) ->
    User.findOne req.session.user, (err, user) ->
      return res.json { error: 'Database error' }, 500 if err

      if user?
        sendgrid.send
          to: process.env.DEVELOPER_EMAIL
          from: user.email
          fromname: user.username
          subject: sails.config.appName + ' のバグ報告'
          text: """
          #{ sails.config.appName } からの自動送信メール
          #{ user.username } さんからのバグ報告です。
          --

          #{ req.body.message }
          """
        , (err, json) ->
          return res.json { error: 'email error' }, 500 if err
          return res.json json
      else
        return res.json { error: 'user not found' }, 404
