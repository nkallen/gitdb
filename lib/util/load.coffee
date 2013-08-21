git = require('nodegit')
path = require('path')

###
Preload data for controller *and* view tiers. cf, http://expressjs.com/api.html#res.locals
###

module.exports = (resolver) ->
  repo: (req, res, next) ->
    git.Repo.open(resolver.resolve(req.params.repo), (err, repo) ->
      return res.send(404, err) if err 

      repo.toString = () -> req.params.repo
      req.repo = res.locals.repo = repo
      next()
    )

  repos: (req, res, next) ->
    req.repos = res.locals.repos = resolver.list()
    next()

  headRef: ref('heads')
  tagRef:  ref('tags')

  remoteRef: (req, res, next) ->
    req.repo.getReference("refs/remotes/#{req.params.remote}/#{req.params.ref}", (err, ref) ->
      return res.send(404, err) if err 

      req.ref = res.locals.ref = ref
      next()
    )


  ref2commit: (req, res, next) ->
    req.repo.getCommit(req.ref.target(), (err, commit) ->
      return res.send(404, err) if err 

      req.commit = res.locals.commit = commit
      next()
    )

  commit2tree: (req, res, next) ->
    req.commit.getTree((err, tree) ->
      return res.send(404, err) if err 

      req.tree = res.locals.tree = tree
      next()
    )

  commit2history: (req, res, next) ->
    req.commits = res.locals.commits = []
    history = req.commit.history()
    history.on('commit', (commit) -> req.commits.push(commit))
    history.on('end', -> next())
    history.on('error', (err) -> res.send(500, err))
    history.start()

  repo2refs: (req, res, next) ->
    req.repo.getReferences(git.Reference.Type.All, (err, refs) ->
      return res.send(500) if err

      req.refs = res.locals.refs = refs
      next()
    )

  tree: (req, res, next) ->
    req.repo.getTree(req.params.sha, (err, tree) ->
      return res.send(404, err) if err 

      req.tree = res.locals.tree = tree
      next()
    )

  blob: (req, res, next) ->
    req.repo.getBlob(req.params.sha, (err, blob) ->
      return res.send(404, err) if err 

      req.blob = res.locals.blob = blob
      next()
    )

  commit: (req, res, next) ->
    req.repo.getCommit(req.params.sha, (err, commit) ->
      return res.send(404, err) if err

      req.commit = res.locals.commit = commit
      next()
    )

  entry: (req, res, next) ->
    if req.params[0] == ''
      req.isTree = res.locals.isTree = true
      req.tree = res.locals.tree = req.tree
      req.entry = res.locals.entry = new RootEntry
      req.entry.oid = () -> req.tree.oid()
      next()
    else
      req.tree.getEntry(req.params[0], (err, entry) ->
        return res.send(404, err) if err

        req.entry = res.locals.entry = entry
        if entry.isTree()
          req.isTree = res.locals.isTree = true
          entry.getTree((err, tree) ->
            return res.send(404, err) if err

            req.tree = res.locals.tree = tree
            next()
          )
        else
          req.isBlob = res.locals.isBlob = true
          entry.getBlob((err, blob) ->
            return res.send(404, err) if err

            req.blob = res.locals.blob = blob
            next()
          )
      )

class RootEntry
  name: () -> ''
  path: () -> ''
  toString: () -> ''
  filemode: () -> git.TreeEntry.FileMode.Tree
  isTree: () -> true
  isBlob: () -> false

ref = (type) ->
  (req, res, next) ->
    req.repo.getReference("refs/#{type}/#{req.params.ref}", (err, ref) ->
      return res.send(404, err) if err 

      req.ref = res.locals.ref = ref
      next()
    )