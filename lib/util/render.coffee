git = require('nodegit')

module.exports.blob = (blob) ->
  throw "blob is null" unless blob

  filemode: blob.filemode()
  encoding: encoding = "base64"
  size: blob.size()
  content: blob.content().toString(encoding)
  sha: blob.oid().toString()

module.exports.tree = (tree) ->
  sha: tree.oid().toString()

module.exports.treeEntry = (entry) ->
  throw "entry is null" unless entry

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

module.exports.commit = (commit) ->
  throw "commit is null" unless commit

  sha: commit.oid().toString()
  message: commit.message()
  author: signature(commit.author())
  committer: signature(commit.committer())
  tree:
    sha: commit.treeId().toString()
  parents: commit.parents()

module.exports.ref = (ref) ->
  throw "ref is null" unless ref

  name: ref.name()
  type: ref.type()
  object:
    if ref.isSymbolic()
      name: ref.symbolicTarget()
    else

module.exports.refName = (refName) ->
  throw "refName is null" unless refName

  name: refName

module.exports.repo = (repo) ->
  throw "repo is null" unless repo

signature = (signature) ->
  date: new Date(signature.time.time * 1000 + signature.time.offset * 60 * 1000)
  name: signature.name()
  email: signature.email()