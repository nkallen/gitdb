git = require('nodegit')
render = require('../util/render')

show = (req, res) ->
  params0 = res.locals.path = req.params[0].replace('/^\//', '')
  res.locals.pathParts = (part for part in params0.split('/') when part)

  if req.isTree then showTree(req, res)
  else               showBlob(req, res)

showTree = (req, res) ->
  res.format(
    'text/html': () ->
      res.render('tree_entries/show_tree.html.ejs')
    'application/json': () ->
      json = render.treeEntry(req.entry)
      json.tree = render.tree(req.tree)
      json.commit = render.commit(req.commit)
      res.json(json)
  )

showBlob = (req, res) ->
  res.format(
    'text/html': () ->
      res.render('tree_entries/show_blob.html.ejs')
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
