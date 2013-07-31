git = require('nodegit')

index = (req, res) ->
  commits = []
  history = req.commit.history()
  history.on('commit', (commit) -> commits.push(commit))
  history.on('end', -> res.render('commits/index.html.ejs', repo: req.params.repo, ref: req.ref, commits: commits))
  history.start()

show = (req, res) ->
  res.render('commits/show.html.ejs', repo: req.params.repo, commit: req.commit)

create = (req, res) ->
  blobs =
    for file in req.params.files
      git.blob.createFromBuffer(file)
  branch = req.repo.master()
  branch.getTree((error, tree) ->
    return res.send(500, error) if error

    builder = tree.builder()
    for file in files
      builder.insert(file.path, file.blob)
    builder.write(req.repo, (error, treeId) ->
      return res.send(500, error) if error

      repo.getTree(treeId, (error, treeId) ->
        return res.send(500, error) if error

        repo.createCommit(null, author, committer, req.params.message, tree, [branch], (error, commitId) ->
          return res.send(500, error) if error

          res.render('commits/create.html.ejs', repo: req.params.repo, commit: req.commit)
        )
      )
    )
  )


module.exports =
  index: index
  show: show
  create: create
