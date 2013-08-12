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

    parts.join('/')


module.exports =
  repo:               url('/repos/:repo')
  refs:               url('/repos/:repo/refs')
  ref:                url('/repos/:repo/:ref')
  headRef:            url('/repos/:repo/refs/heads/:ref')
  tagRef:             url('/repos/:repo/refs/tags/:ref')
  remoteRef:          url('/repos/:repo/refs/remotes/:remote/:ref')
  refCommits:         url('/repos/:repo/refs/:ref/commits')
  headRefCommits:     url('/repos/:repo/refs/heads/:ref/commits')
  tagRefCommits:      url('/repos/:repo/refs/tags/:ref/commits')
  remoteRefCommits:   url('/repos/:repo/refs/remotes/:remote/:ref/commits')
  refTreeEntry:       url('/repos/:repo/refs/:ref/tree/*')
  headRefTreeEntry:   url('/repos/:repo/refs/heads/:ref/tree/*')
  remoteRefTreeEntry: url('/repos/:repo/refs/remotes/:remote/:ref/tree/*')
  tagRefTreeEntry:    url('/repos/:repo/refs/tags/:ref/tree/*')
  blob:               url('/repos/:repo/blobs/:sha')
  commit:             url('/repos/:repo/commits/:sha')
  commitTreeEntry:    url('/repos/:repo/commits/:sha/tree/*')
