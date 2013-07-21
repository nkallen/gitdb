git = require('nodegit')

show = (req, res) ->
  if req.entry instanceof git.Tree
    res.render('tree_entries/show_tree.html.ejs', repo: req.params.repo, commit: req.commit, tree: req.entry, path: req.path)
  else
    res.render('tree_entries/show_blob.html.ejs', repo: req.params.repo, commit: req.commit, blob: req.entry, path: req.path)

module.exports =
  show: show
