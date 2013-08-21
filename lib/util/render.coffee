git = require('nodegit')
url = require('./url')

blob = (locals, blob, hideContext) ->
  result =
    filemode: blob.filemode()
    encoding: encoding = "base64"
    size: blob.size()
    content: blob.content().toString(encoding)
    sha: blob.oid().toString()
    url: url.blob(locals.repo, blob.oid())

  if !hideContext
    result.commit = commit(locals, locals.commit) if locals.commit
    result.ref = ref(locals, locals.ref)          if locals.ref
    result.repo = repo(locals, locals.repo)       if locals.repo
  result    

tree = (locals, tree, hideContext) ->
  result = 
    sha: tree.oid().toString()
    url: url.treeEntry(locals.repo, tree.oid())
    entries: treeEntry(locals, entry, true) for entry in tree.entries()

  if !hideContext
    result.commit = commit(locals, locals.commit) if locals.commit
    result.ref = ref(locals, locals.ref)          if locals.ref
    result.repo = repo(locals, locals.repo)       if locals.repo
  result

treeEntry = (locals, entry, hideContext) ->
  result =
    name: entry.name()
    path: entry.path()
    type:
      switch entry.filemode()
        when git.TreeEntry.FileMode.Tree   then "tree"
        when git.TreeEntry.FileMode.Blob       then "blob"
        when git.TreeEntry.FileMode.Executable then "blob"
        when git.TreeEntry.FileMode.Link   then "link"
        when git.TreeEntry.FileMode.Commit then "commit"
        when git.TreeEntry.FileMode.New    then "new"
    filemode: entry.filemode()
    commit_relative_url: url.commitTreeEntry(locals.repo, locals.commit, entry)
    tree_relative_url: url.treeEntry(locals.repo, locals.tree.oid(), entry)

  result.ref_relative_url = url.refTreeEntry(locals.repo, locals.ref, entry) if locals.ref

  if entry.isTree()
    result.url = url.treeEntry(locals.repo, entry.oid())
  else if entry.isBlob()
    result.url = url.blob(locals.repo, entry.oid())

  if !hideContext
    if entry.isTree()
      result.tree =
        tree(locals, locals.tree, true)
    else if entry.isBlob()
      result.blob =
        blob(locals, locals.blob, true)

    result.commit = commit(locals, locals.commit) if locals.commit
    result.ref = ref(locals, locals.ref)          if locals.ref
    result.repo = repo(locals, locals.repo)       if locals.repo
  result

commit = (locals, commit, hideContext) ->
  result =
    sha: commit.oid().toString()
    message: commit.message()
    author: signature(commit.author())
    committer: signature(commit.committer())
    tree:
      sha: commit.treeId().toString()
    parents: { sha: parent.toString(), url: url.commit(locals.repo, parent) } for parent in commit.parents()
    url: url.commit(locals.repo, commit)
    tree_url: url.commitTreeEntry(locals.repo, commit)
  if !hideContext
    result.repo = repo(locals, locals.repo)       if locals.repo
  result

ref = (locals, ref, hideContext) ->
  result =
    name: ref.name()
    type: ref.type()
    object:
      if ref.isSymbolic()
        name: ref.symbolicTarget()
        url: url.ref(locals.repo, ref.symbolicTarget())
      else
        sha: ref.target().toString()
    url: url.ref(locals.repo, ref)
    commits_url: url.refCommits(locals.repo, ref)
    tree_url: url.refTreeEntry(locals.repo, ref)
  if !hideContext
    result.repo = repo(locals, locals.repo)       if locals.repo
  result

refName = (locals, refName, hideContext) ->
  name: refName
  url: url.ref(locals.repo, refName)

repo = (locals, repo, hideContext) ->
  url: url.repo(repo)
  refs_url: url.refs(repo)

signature = (signature) ->
  date: new Date(signature.time().time() * 1000 + signature.time().offset() * 60 * 1000)
  name: signature.name()
  email: signature.email()

module.exports =
  blob: blob
  tree: tree
  treeEntry: treeEntry
  commit: commit
  ref: ref
  refName: refName
  repo: repo