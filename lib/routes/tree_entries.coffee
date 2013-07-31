git = require('nodegit')
path = require('path')

show = (req, res) ->
  pathParts = req.params[0].split(path.sep)
  root =
    if req.ref
      "/repos/#{req.params.repo}/#{req.ref.name()}"
    else
      "/repos/#{req.params.repo}/commits/#{req.commit}"

  if req.entry instanceof git.Tree
    res.render('tree_entries/show_tree.html.ejs', repo: req.params.repo, ref: req.ref, commit: req.commit, tree: req.entry, pathParts: pathParts, path: req.params[0], root: root)
  else
    res.render('tree_entries/show_blob.html.ejs', repo: req.params.repo, ref: req.ref, commit: req.commit, blob: req.entry, pathParts: pathParts, path: req.params[0], root: root)

module.exports =
  show: show
