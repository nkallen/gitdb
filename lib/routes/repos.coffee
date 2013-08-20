git = require('nodegit')
render = require('../util/render')

show = (req, res) ->
  res.format(
    'text/html': () ->
      res.render('repos/show.html.ejs')
    'application/json': () ->
      res.json(render.repo(res.locals, req.repo))
  )

index = (req, res) ->
  res.format(
    'text/html': () ->
      res.render('repos/index.html.ejs')
    'application/json': () ->
      res.json(render.repo(res.locals, repo) for repo in req.repos)
  )

module.exports =
  show: show
  index: index
