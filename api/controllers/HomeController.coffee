module.exports =

  index: (req, res) ->
    Notification.find().sort('createdAt DESC').limit(3).done (err, notifications) ->
      res.json err, 500 if err
      return res.view
        notifications: notifications
