git = require('nodegit')
path = require('path')

module.exports = (repoRoot) ->
  ref = (type) ->
    (req, res, next) ->
      req.repo.getReference("refs/#{type}/#{req.params.ref}", (err, ref) ->
        return res.send(404, err) if err 

        req.ref = ref
        next()
      )

  repo: (req, res, next) ->
    git.Repo.open(path.join(repoRoot, req.params.repo, '.git'), (err, repo) ->
      return res.send(404, err) if err 

      req.repo = repo
      next()
    )

  headRef:  ref('heads')
  tagRef: ref('tags')

  remoteRef: (req, res, next) ->
    req.repo.getReference("refs/remotes/#{req.params.remote}/#{req.params.ref}", (err, ref) ->
      return res.send(404, err) if err 

      req.ref = ref
      next()
    )


  ref2commit: (req, res, next) ->
    req.repo.getCommit(req.ref.target(), (err, commit) ->
      return res.send(404, err) if err 

      req.commit = commit
      next()
    )

  commit2tree: (req, res, next) ->
    req.commit.getTree((err, tree) ->
      return res.send(404, err) if err 

      req.tree = tree
      next()
    )

  blob: (req, res, next) ->
    req.repo.getBlob(req.params.sha, (err, blob) ->
      return res.send(404, err) if err 

      req.blob = blob
      next()
    )

  commit: (req, res, next) ->
    req.repo.getCommit(req.params.sha, (err, commit) ->
      return res.send(404, err) if err

      req.commit = commit
      next()
    )

  entry: (req, res, next) ->
    if req.params[0] == ''
      req.isTree = true
      req.tree = req.tree
      next()
    else
      req.tree.getEntry(req.params[0], (err, entry) ->
        return res.send(404, err) if err

        req.entry = entry
        if entry.isTree()
          req.isTree = true
          entry.getTree((err, tree) ->
            return res.send(404, err) if err

            req.tree = tree
            tree.entry = entry
            next()
          )
        else
          req.isBlob = true
          entry.getBlob((err, blob) ->
            return res.send(404, err) if err

            req.blob = blob
            blob.entry = entry
            next()
          )
      )