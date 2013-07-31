express = require('express')
git     = require('nodegit')
path    = require('path')

refs        = require('./routes/refs')
treeEntries = require('./routes/tree_entries')
blobs       = require('./routes/blobs')
commits     = require('./routes/commits')
history     = require('./routes/history')
repo        = require('./routes/repos')

app = express()

app.use(express.responseTime())
app.use(express.bodyParser())
app.use(express.methodOverride())
app.use(express.compress())
app.set('view engine', 'ejs')
app.set('views', __dirname + '/views')

app.enable('strict routing')

REPO_ROOT = path.resolve(process.env.REPO_ROOT || path.join(__dirname, '..', '..'))

loadRepo = (req, res, next) ->
  git.Repo.open(path.join(REPO_ROOT, req.params.repo, '.git'), (err, repo) ->
    return res.send(404, err) if err 

    req.repo = repo
    next()
  )

loadRef = (type) -> (req, res, next) ->
  req.repo.getReference("refs/#{type}/#{req.params.ref}", (err, ref) ->
    return res.send(404, err) if err 

    req.ref = ref
    next()
  )

loadHeadRef   = loadRef('heads')
loadTagRef    = loadRef('tags')

loadRemoteRef = (req, res, next) ->
  req.repo.getReference("refs/remotes/#{req.params.remote}/#{req.params.ref}", (err, ref) ->
    return res.send(404, err) if err 

    req.ref = ref
    next()
  )


ref2commit = (req, res, next) ->
  req.repo.getCommit(req.ref.oid(), (err, commit) ->
    return res.send(404, err) if err 

    req.commit = commit
    next()
  )

commit2tree = (req, res, next) ->
  req.commit.getTree((err, tree) ->
    return res.send(404, err) if err 

    req.tree = tree
    next()
  )

loadBlob = (req, res, next) ->
  req.repo.getBlob(req.params.sha, (err, blob) ->
    return res.send(404, err) if err 

    req.blob = blob
    next()
  )

loadCommit = (req, res, next) ->
  req.repo.getCommit(req.params.sha, (err, commit) ->
    return res.send(404, err) if err

    req.commit = commit
    next()
  )

loadEntry = (req, res, next) ->
  if req.params[0] == ''
    req.entry = req.tree
    next()
  else
    req.tree.getEntry(req.params[0], (err, entry) ->
      return res.send(404, err) if err

      if entry.isTree()
        entry.getTree((err, tree) ->
          return res.send(404, err) if err

          req.entry = tree
          next()
        )
      else
        entry.getBlob((err, blob) ->
          return res.send(404, err) if err

          req.entry = blob
          next()
        )
    )

app.param((name, fn) ->
  if fn instanceof RegExp
    (req, res, next, val) ->
      console.log(fn, val, fn.exec(String(val)))
      if captures = fn.exec(String(val))
        req.params[name] = captures
        next()
      else
        next('route')
)

app.get('/repos/:repo',                                   [loadRepo],                                                     repo.show)
app.get('/repos/:repo/refs',                              [loadRepo],                                                     refs.index)
app.get('/repos/:repo/refs/heads/:ref',                   [loadRepo, loadHeadRef],                                        refs.show)
app.get('/repos/:repo/refs/tags/:ref',                    [loadRepo, loadTagRef],                                         refs.show)
app.get('/repos/:repo/refs/remotes/:remote/:ref',         [loadRepo, loadRemoteRef],                                      refs.show)
app.get('/repos/:repo/refs/heads/:ref/commits',           [loadRepo, loadHeadRef, ref2commit],                            commits.index)
app.put('/repos/:repo/refs/heads/:ref/commits',           [loadRepo, loadHeadRef, ref2commit],                            commits.create)
app.get('/repos/:repo/refs/tags/:ref/commits',            [loadRepo, loadTagRef, ref2commit],                             commits.index)
app.get('/repos/:repo/refs/remotes/:remote/:ref/commits', [loadRepo, loadRemoteRef, ref2commit],                          commits.index)
app.get('/repos/:repo/refs/heads/:ref/*',                 [loadRepo, loadHeadRef, ref2commit, commit2tree, loadEntry],    treeEntries.show)
app.get('/repos/:repo/refs/remotes/:remote/:ref/*',       [loadRepo, loadRemoteRef, ref2commit, commit2tree, loadEntry],  treeEntries.show)
app.get('/repos/:repo/refs/tags/:ref/*',                  [loadRepo, loadTagRef, ref2commit, commit2tree, loadEntry],     treeEntries.show)
app.get('/repos/:repo/blobs/:sha',                        [loadRepo, loadBlob],                                           blobs.show)
app.get('/repos/:repo/commits/:sha',                      [loadRepo, loadCommit],                                         commits.show)
app.get('/repos/:repo/commits/:sha/*',                    [loadRepo, loadCommit, commit2tree, loadEntry],                 treeEntries.show)

app.get('/', (req, res) ->
  res.render('index.html.ejs')
)

app.listen(process.env.PORT)
