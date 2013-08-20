git = require('nodegit')
render = require('../util/render')

show = (req, res) ->
  params0 = res.locals.path = req.params[0].replace('/^\//', '')
  res.locals.pathParts = (part for part in params0.split('/') when part)

  if req.isTree      then showTree(req, res)
  else if req.isBlob then showBlob(req, res)
  else res.send(500, "Unsupported tree entry type")

showTree = (req, res) ->
  res.format(
    'text/html': () ->
      res.render('tree_entries/show_tree.html.ejs')
    'application/json': () ->
      res.json(render.treeEntry(res.locals, req.entry))
  )

showBlob = (req, res) ->
  res.format(
    'text/html': () ->
      res.render('tree_entries/show_blob.html.ejs')
    'application/json': () ->
      res.json(render.treeEntry(res.locals, req.entry))
    'application/vnd.gitdb.raw': () ->
      res.json(req.blob.toString())
  )

module.exports =
  show: show
