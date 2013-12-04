render = require('../util/render')
url = require('../util/url')

show = (req, res) ->
  res.format(
    'text/html': () ->
      res.render('blobs/show.html.ejs')
    'application/json': () ->
      res.json(render.blob(res.locals, req.blob))
    'application/vnd.gitdb.raw': () ->
      res.json(req.blob.content())
  )

create = (req, res) ->
  req.repo.createBlobFromBuffer new Buffer(req.body.content, req.body.encoding), (error, blobId) ->
    return res.send(500, error) if error
    res.format(
      'application/json': () ->
        res.location(url.blob(req.repo, blobId))
        res.send(201, {sha: blobId.toString()})
    )

module.exports =
  show: show
  create: create