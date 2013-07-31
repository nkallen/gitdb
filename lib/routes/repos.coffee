git = require('nodegit')

show = (req, res) ->
  res.render('repos/show.html.ejs', repo: req.params.repo)

module.exports =
  show: show
