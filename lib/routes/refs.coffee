git = require('nodegit')

index = (req, res) ->
  req.repo.getReferences(git.Reference.Type.All, (err, refs) ->
    return res.send(500) if err

    res.render('refs/index.html.ejs', repo: req.params.repo, refs: refs)
  )

show = (req, res) ->
  res.render('refs/show.html.ejs', repo: req.params.repo, ref: req.ref)

create = (req, res) ->

module.exports =
  index: index
  show: show
  create: create
