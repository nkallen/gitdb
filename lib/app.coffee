express = require('express')
git     = require('nodegit')
path    = require('path')

module.exports = (resolver) ->
  load        = require('./util/load')(resolver)
  url         = require('./util/url')

  refs        = require('./routes/refs')
  treeEntries = require('./routes/tree_entries')
  blobs       = require('./routes/blobs')
  commits     = require('./routes/commits')
  repo        = require('./routes/repos')

  app = express()
  app.use(express.responseTime())
  app.use(express.compress())
  app.use(express.bodyParser())
  app.use(express.methodOverride())
  app.set('view engine', 'ejs')
  app.set('views', __dirname + '/views')
  app.locals.url = url

  app.get(url.repo(),               [load.repos, load.repo],                                                                      repo.show)
  app.get(url.repos(),              [load.repos],                                                                                 repo.index)
  app.get(url.refs(),               [load.repos, load.repo, load.repo2refs],                                                      refs.index)
  app.get(url.headRef(),            [load.repos, load.repo, load.headRef],                                                        refs.show)
  app.get(url.tagRef(),             [load.repos, load.repo, load.tagRef],                                                         refs.show)
  app.get(url.remoteRef(),          [load.repos, load.repo, load.remoteRef],                                                      refs.show)
  app.get(url.headRefCommits(),     [load.repos, load.repo, load.headRef, load.ref2commit, load.commit2history],                  commits.index)
  app.patch(url.headRef(),          [load.repos, load.repo, load.headRef, load.ref2commit, load.commit2tree],                     commits.update)
  app.get(url.tagRefCommits(),      [load.repos, load.repo, load.tagRef, load.ref2commit, load.commit2history],                   commits.index)
  app.get(url.remoteRefCommits(),   [load.repos, load.repo, load.remoteRef, load.ref2commit, load.commit2history],                commits.index)
  app.get(url.headRefTreeEntry(),   [load.repos, load.repo, load.headRef, load.ref2commit, load.commit2tree, load.entry],         treeEntries.show)
  app.put(url.headRefTreeEntry(),   [load.repos, load.repo, load.headRef, load.ref2commit, load.commit2tree, load.entryOptional], treeEntries.update)
  app.get(url.remoteRefTreeEntry(), [load.repos, load.repo, load.remoteRef, load.ref2commit, load.commit2tree, load.entry],       treeEntries.show)
  app.get(url.tagRefTreeEntry(),    [load.repos, load.repo, load.tagRef, load.ref2commit, load.commit2tree, load.entry],          treeEntries.show)
  app.get(url.blob(),               [load.repos, load.repo, load.blob],                                                           blobs.show)
  app.post(url.commits(),           [load.repos, load.repo, load.parentCommit],                                                   commits.create)
  app.get(url.commit(),             [load.repos, load.repo, load.commit, load.commit2diffList],                                   commits.show)
  app.get(url.commitTreeEntry(),    [load.repos, load.repo, load.commit, load.commit2tree, load.entry],                           treeEntries.show)
  app.get(url.treeEntry(),          [load.repos, load.repo, load.tree, load.entry],                                               treeEntries.show)
  app.get('/', [load.repos],
    (req, res) -> res.render('index.html.ejs'))

  app