fs = require('fs')
path = require('path')
app = require('./app')

class Resolver
  constructor: (@repoRoot) ->
  resolve: (repoName) -> path.join(@repoRoot, repoName, '.git')
  list: -> fs.readdirSync(@repoRoot)

app.configure('test', ->
  app.set('resolver', new Resolver(path.join(__dirname, '..', '..')))

  app.use((err, req, res, next) ->
    console.error(err.stack)
    res.send(500)
  )
)

app.configure('development', ->
  app.set('resolver', new Resolver(path.join(__dirname, '..', '..')))
  app.listen(process.env.PORT)
)

app.configure('production', ->
  app.set('resolver', new Resolver(path.resolve(process.env.REPO_ROOT)))
  app.listen(process.env.PORT)
)

module.exports = app