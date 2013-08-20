git = require('nodegit')
render = require('../util/render')

show = (req, res) ->
  res.format(
    'text/html': () ->
      res.render('repos/show.html.ejs')
    'application/json': () ->
      res.json(render.repo(req.repo))
  )

module.exports =
  show: show
