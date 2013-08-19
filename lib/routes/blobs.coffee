render = require('../util/render')

show = (req, res) ->
  res.format(
    'text/html': () ->
      res.render('blobs/show.html.ejs', repo: req.params.repo, blob: req.blob)
    'application/json': () ->
      res.json(render.blob(req.blob))
    'application/vnd.gitdb.raw': () ->
      res.json(req.blob.content())
  )

module.exports =
  show: show
