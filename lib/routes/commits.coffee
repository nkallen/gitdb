git = require('nodegit')
render = require('../util/render')

index = (req, res) ->
  commits = []
  history = req.commit.history()
  history.on('commit', (commit) -> commits.push(commit))
  history.on('end', ->
    res.format(
      'text/html': () ->
        res.render('commits/index.html.ejs', repo: req.params.repo, ref: req.ref, commits: commits)
      'application/json': () ->
        res.json(render.commit(commit) for commit in commits)
    )
  )
  history.start()

show = (req, res) ->
  res.format(
    'text/html': () ->
      res.render('commits/show.html.ejs', repo: req.params.repo, commit: req.commit)
    'application/json': () ->
      res.json(render.commit(req.commit))
  )

create = (req, res) ->
  req.repo.getCommit(req.body.parents[0], (error, commit) ->
    return res.send(500, error) if error

    commit.getTree((error, tree) ->
      return res.send(500, error) if error

      builder = tree.builder()
      for insertion in req.body.tree
        builder.insertBlob(insertion.path, new Buffer(insertion.content, insertion.encoding), insertion.filemode == git.TreeEntry.FileMode.Executable)

      builder.write((error, treeId) ->
        return res.send(500, error) if error

        author = git.Signature.create(req.body.author.name, req.body.author.email, 123456789, 60)
        committer = git.Signature.create(req.body.committer.name, req.body.committer.email, 987654321, 90)

        req.repo.createCommit(req.ref, author, committer, req.body.message, treeId, [commit], (error, commitId) ->
          return res.send(500, error) if error

          req.repo.getCommit(commitId, (err, commit) ->
            return res.send(500, error) if error

            res.format(
              'application/json': () -> res.send(201, render.commit(commit))
            )
          )
        )
      )
    )
  )

module.exports =
  index: index
  show: show
  create: create
