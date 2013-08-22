git = require('nodegit')
render = require('../util/render')
url = require('../util/url')

index = (req, res) ->
  res.format(
    'text/html': () ->
      res.render('commits/index.html.ejs')
    'application/json': () ->
      res.json(render.commit(res.locals, commit) for commit in req.commits)
  )

show = (req, res) ->
  res.format(
    'text/html': () ->
      res.render('commits/show.html.ejs')
    'application/json': () ->
      res.json(render.commit(res.locals, req.commit))
  )

update = (req, res) ->
  return res.send(400) unless req.get('If-Match')
  return res.send(412) unless req.commit.oid().sha() == req.get('If-Match')
  create(req, res)

create = (req, res) ->
  builder = req.tree.builder()
  for insertion in req.body.tree
    builder.insertBlob(insertion.path, new Buffer(insertion.content, insertion.encoding), insertion.filemode == git.TreeEntry.FileMode.Executable)

  builder.write((error, treeId) ->
    return res.send(500, error) if error

    author = git.Signature.create(req.body.author.name, req.body.author.email, 123456789, 60)
    committer = git.Signature.create(req.body.committer.name, req.body.committer.email, 987654321, 90)

    req.repo.createCommit(req.ref, author, committer, req.body.message, treeId, [req.commit], (error, commitId) ->
      return res.send(500, error) if error

      req.repo.getCommit(commitId, (err, commit) ->
        return res.send(500, error) if error

        res.format(
          'application/json': () ->
            res.location(url.commit(req.repo, commit))
            res.send(201, render.commit(res.locals, commit))
        )
      )
    )
  )

treeId2commit = (req, res) ->

module.exports =
  index: index
  show: show
  create: create
  update: update
