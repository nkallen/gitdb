git = require('nodegit')
render = require('../util/render')

index = (req, res) ->
  res.format(
    'text/html': () ->
      res.render('refs/index.html.ejs')
    'application/json': () ->
      res.json(render.refName(res.locals, ref) for ref in req.refs)
  )

show = (req, res) ->
  res.format(
    'text/html': () ->
      res.render('refs/show.html.ejs')
    'application/json': () ->
      res.json(render.ref(res.locals, req.ref))
  )

create = (req, res) ->

module.exports =
  index: index
  show: show
  create: create
