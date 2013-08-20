render = require('../util/render')

show = (req, res) ->
  res.format(
    'text/html': () ->
      res.render('blobs/show.html.ejs')
    'application/json': () ->
      res.json(render.blob(res.locals, req.blob))
    'application/vnd.gitdb.raw': () ->
      res.json(req.blob.content())
  )

module.exports =
  show: show
