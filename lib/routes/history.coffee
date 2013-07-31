git = require('nodegit')

show = (req, res) ->
  commits = []
  history = req.commit.history()
  history.on('commit', (commit) -> commits.push(commit))
  history.on('end', -> res.render('history/show.html.ejs', repo: req.params.repo, ref: req.ref, commits: commits))
  history.start()

module.exports =
  show: show
