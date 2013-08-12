git = require('nodegit')
path = require('path')

show = (req, res) ->
  params0 = req.params[0].replace('/^\//', '')
  req.pathParts = (part for part in params0.split(path.sep) when part)
  req._path = params0

  if req.entry instanceof git.Tree
    showTree(req, res)
  else
    showBlob(req, res)

showTree = (req, res) ->
  res.format(
    'text/html': () ->
      res.render('tree_entries/show_tree.html.ejs', repo: req.params.repo, ref: req.ref, commit: req.commit, tree: req.entry, pathParts: req.pathParts, path: req._path)
    'application/json': () ->
    'application/vnd.gitdb.raw': () ->
  )

showBlob = (req, res) ->
  res.format(
    'text/html': () ->
      res.render('tree_entries/show_blob.html.ejs', repo: req.params.repo, ref: req.ref, commit: req.commit, blob: req.entry, pathParts: req.pathParts, path: req._path)
    'application/json': () ->
      res.send(200,
        filemode: req.entry.filemode()
        encoding: encoding = "base64"
        size: req.entry.size()
        name: req.pathParts[req.pathParts.length - 1]
        path: req.params[0]
        content: req.entry.content().toString(encoding)
        sha: req.entry.oid().toString()
        commit:
          sha: req.commit.oid().toString()
      )
    'application/vnd.gitdb.raw': () ->
      res.send(200, req.entry.toString())
  )

module.exports =
  show: show
