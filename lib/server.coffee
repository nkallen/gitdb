fs = require('fs')
path = require('path')

REPO_ROOT = path.resolve(process.env.REPO_ROOT || path.join(__dirname, '..', '..'))
LIST = fs.readdirSync(REPO_ROOT)

resolver =
  resolve: (repoName) -> path.join(REPO_ROOT, repoName, '.git')
  list: () -> LIST

app = require('./app')(resolver)
app.listen(process.env.PORT || 80)