git = require('nodegit')
render = require('../util/render')

show = (req, res) ->
  params0 = req.params[0].replace('/^\//', '')
  req.pathParts = (part for part in params0.split('/') when part)
  req._path = params0

  if req.isTree
    showTree(req, res)
  else
    showBlob(req, res)

showTree = (req, res) ->
  res.format(
    'text/html': () ->
      res.render('tree_entries/show_tree.html.ejs', repo: req.params.repo, ref: req.ref, commit: req.commit, tree: req.tree, pathParts: req.pathParts, path: req._path)
    'application/json': () ->
      json = render.treeEntry(req.entry)
      json.tree = render.tree(req.tree)
      json.commit = render.commit(req.commit)
      res.json(json)
  )

showBlob = (req, res) ->
  res.format(
    'text/html': () ->
      res.render('tree_entries/show_blob.html.ejs', repo: req.params.repo, ref: req.ref, commit: req.commit, blob: req.blob, pathParts: req.pathParts, path: req._path)
    'application/json': () ->
      json = render.treeEntry(req.entry)
      json.blob = render.blob(req.blob)
      json.commit = render.commit(req.commit)
      res.json(json)
    'application/vnd.gitdb.raw': () ->
      res.json(req.blob.toString())
  )

module.exports =
  show: show
