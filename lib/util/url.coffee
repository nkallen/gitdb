path = require('path')

param = (args) ->
  args.shift()

constant = (string) -> () ->
  string

splat = (args) ->
  (arg for arg in args when arg).join('/')

url = (template) ->
  templateParts = template.split('/')
  partSpecs = for templatePart, i in templateParts
    if /^:/.test(templatePart)
      param
    else if /^\*$/.test(templatePart)
      splat
    else
      constant(templatePart)
  () ->
    return template unless arguments.length
    args = (argument for argument in arguments)

    parts = for partSpec in partSpecs
      partSpec(args)

    (part for part in parts).join('/')


module.exports =
  repo:               url('/repos/:repo')
  repos:              url('/repos')
  refs:               url('/repos/:repo/refs')
  ref:                url('/repos/:repo/:ref')
  headRef:            url('/repos/:repo/refs/heads/:ref')
  tagRef:             url('/repos/:repo/refs/tags/:ref')
  remoteRef:          url('/repos/:repo/refs/remotes/:remote/:ref')
  refCommits:         url('/repos/:repo/:ref/log')
  headRefCommits:     url('/repos/:repo/refs/heads/:ref/log')
  tagRefCommits:      url('/repos/:repo/refs/tags/:ref/log')
  remoteRefCommits:   url('/repos/:repo/refs/remotes/:remote/:ref/log')
  refTreeEntry:       url('/repos/:repo/:ref/tree/*')
  headRefTreeEntry:   url('/repos/:repo/refs/heads/:ref/tree/*')
  remoteRefTreeEntry: url('/repos/:repo/refs/remotes/:remote/:ref/tree/*')
  tagRefTreeEntry:    url('/repos/:repo/refs/tags/:ref/tree/*')
  blob:               url('/repos/:repo/blobs/:sha')
  commits:            url('/repos/:repo/commits')
  commit:             url('/repos/:repo/commits/:sha')
  commitTreeEntry:    url('/repos/:repo/commits/:sha/tree/*')
  treeEntry:          url('/repos/:repo/trees/:sha/*')
