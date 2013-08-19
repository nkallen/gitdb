git = require('nodegit')
render = require('../util/render')

index = (req, res) ->
  req.repo.getReferences(git.Reference.Type.All, (err, refs) ->
    return res.send(500) if err

    res.format(
      'text/html': () ->
        res.render('refs/index.html.ejs', repo: req.params.repo, refs: refs)
      'application/json': () ->
        res.json(render.refName(ref) for ref in refs)
    )
  )

show = (req, res) ->
  res.format(
    'text/html': () ->
      res.render('refs/show.html.ejs', repo: req.params.repo, ref: req.ref)
    'application/json': () ->
      res.json(render.ref(req.ref))
  )

create = (req, res) ->

module.exports =
  index: index
  show: show
  create: create
