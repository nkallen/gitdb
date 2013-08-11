git = require('nodegit')
path = require('path')

show = (req, res) ->
  req.pathParts = req.params[0].split(path.sep)
  req.root =
    if req.ref
      "/repos/#{req.params.repo}/#{req.ref.name()}"
    else
      "/repos/#{req.params.repo}/commits/#{req.commit}"
  _path = req.path
  req._path = if _path[_path.length - 1] == '/'
    _path[0..-2]
  else
    _path

  if req.entry instanceof git.Tree
    showTree(req, res)
  else
    showBlob(req, res)

showTree = (req, res) ->
  res.format(
    'text/html': () ->
      res.render('tree_entries/show_tree.html.ejs', repo: req.params.repo, ref: req.ref, commit: req.commit, tree: req.entry, pathParts: req.pathParts, path: req._path, root: req.root)
    'application/json': () ->
    'application/vnd.gitdb.raw': () ->
  )

showBlob = (req, res) ->
  res.format(
    'text/html': () ->
      res.render('tree_entries/show_blob.html.ejs', repo: req.params.repo, ref: req.ref, commit: req.commit, blob: req.entry, pathParts: req.pathParts, path: req._path, root: req.root)
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
