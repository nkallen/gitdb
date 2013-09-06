git = require('nodegit')
render = require('../util/render')
url = require('../util/url')

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

update = (req, res) ->
  return res.send(422, 'can only create or update a blob') if req.entry && !req.isBlob
  return res.send(400) unless req.get('If-Match')
  return res.send(412, 'If-Match fails') unless req.blob.oid().sha() == req.get('If-Match')

  builder = req.tree.builder()
  builder.insertBlob(req.params[0], new Buffer(req.body.content, req.body.encoding), req.body.filemode == git.TreeEntry.FileMode.Executable)

  builder.write((error, treeId) ->
    return res.send(500, error) if error

    author = git.Signature.create(req.body.author.name, req.body.author.email, 123456789, 60)
    committer = git.Signature.create(req.body.committer.name, req.body.committer.email, 987654321, 90)

    req.repo.createCommit(req.ref.toString(), author, committer, req.body.message, treeId, [req.commit], (error, commitId) ->
      return res.send(500, error) if error

      req.repo.getCommit(commitId, (err, commit) ->
        return res.send(500, error) if error

        res.locals.commit = commit
        commit.getTree((error, tree) ->
          return res.send(500, error) if error

          tree.getEntry(req.params[0], (error, entry) ->
            return res.send(500, error) if error

            res.locals.entry = entry
            entry.getBlob((error, blob) ->
              return res.send(500, error) if error

              res.locals.blob = blob
              res.format(
                'application/json': () ->
                  if req.entry
                    code = 201
                    res.location(url.blob(req.repo, blob.oid()))
                  else
                    code = 200
                  res.send(code, render.treeEntry(res.locals, entry))
              )
            )
          )
        )
      )
    )
  )

create = (req, res) ->
  builder = req.repo.treeBuilder(null)
  for path in req.body.paths
    builder.insert(path.path, git.Oid.fromString(path.sha, null), path.filemode)
  builder.write (error, treeId) ->
    return res.send(500, error) if error
    res.format(
      'application/json': () ->
        res.location(url.treeEntry(req.repo, treeId))
        res.send(201, {sha: treeId.toString()})
    )

module.exports =
  show: show
  update: update
  create: create