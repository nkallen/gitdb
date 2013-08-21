path = require('path')

module.exports =
  resolver:
    resolve: (repoName) -> path.join(path.join(__dirname, '..', '..'), repoName, '.git')
    list: () -> ['gitdb']
