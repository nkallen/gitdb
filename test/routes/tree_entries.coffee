helper = require('../helper')
app = require('../../lib/app')(helper.resolver)
request = require('supertest')
git = require('nodegit')

describe 'tree_entries', ->
  describe 'show', ->
    describe 'tree', ->
      uri = '/repos/gitdb/commits/a4fd4d1b5368664ee291adf539db0ba40935df5b/tree/lib'
      describe 'html', ->
        it 'works', (done) ->
          request(app)
            .get(uri)
            .set('Accept', 'text/html')
            .expect('Content-Type', /html/)
            .expect(200, done)
      describe 'json', ->
        it 'works', (done) ->
          request(app)
            .get(uri)
            .set('Accept', 'application/json')
            .expect('Content-Type', /json/)
            .expect(200, done)

    describe 'blob', ->
      uri = '/repos/gitdb/commits/a4fd4d1b5368664ee291adf539db0ba40935df5b/tree/README.md'
      describe 'html', ->
        it 'works', (done) ->
          request(app)
            .get(uri)
            .set('Accept', 'text/html')
            .expect('Content-Type', /html/)
            .expect(200, done)
      describe 'json', ->
        it 'works', (done) ->
          request(app)
            .get(uri)
            .set('Accept', 'application/json')
            .expect('Content-Type', /json/)
            .expect(200, done)
      describe 'raw', ->
        it 'works', (done) ->
          request(app)
            .get(uri)
            .set('Accept', 'application/vnd.gitdb.raw')
            .expect('Content-Type', /raw/)
            .expect(200, done)

  describe 'update', ->
    uri = '/repos/gitdb/refs/heads/test/tree/README.md'
    describe 'json', ->
      it 'works', (done) ->
        request(app)
          .get(uri)
          .set('Accept', 'application/json')
          .end((error, res) ->
            previousSha = res.body.blob.sha

            request(app)
              .put(uri)
              .set('Accept', 'application/json')
              .set('If-Match', previousSha)
              .send(
                message: 'A new idea for a song lyric ' + new Date()
                content: 'Get on the bus, Gus'
                encoding: 'utf8'
                filemode: git.TreeEntry.FileMode.Blob
                author:
                  name: 'Paul Simon'
                  email: 'paul@simon.com'
                  time: new Date()
                  offset: 0
                committer:
                  name: 'Art Garfunkle'
                  email: 'art@garfunkle.com'
                  time: new Date()
                  offset: 0
              )
              .expect('Content-Type', /json/)
              .expect(201, done)
          )

  describe 'create', ->
    uri = '/repos/gitdb/trees'
    describe 'json', ->
      it 'works', (done) ->
        request(app)
          .post(uri)
          .set('Accept', 'application/json')
          .send(
            paths: [
              { filemode: git.TreeEntry.FileMode.Blob, sha: 'f84a43d3fd85d5ee9460ea238512e300a02d86ee', path: '.gitignore' },
              { filemode: git.TreeEntry.FileMode.Blob, sha: 'f993ab7031358e67e00c1b039707e61db8e5e6dd', path: 'README.md' },
              { filemode: git.TreeEntry.FileMode.Blob, sha: 'f993ab7031358e67e00c1b039707e61db8e5e6dd', path: 'README-test.md' },
              { filemode: git.TreeEntry.FileMode.Blob, sha: '7ca55815246c09a324ac2eaadacba508efae4670', path: 'TODO' },
              { filemode: git.TreeEntry.FileMode.Tree, sha: '854a1624a4323cce5bf47ab2bdd721f42d6bc97a', path: 'lib' },
              { filemode: git.TreeEntry.FileMode.Blob, sha: 'be8f0f9a016acb443ae95c61336fd6f93a9033ce', path: 'package.json' },
              { filemode: git.TreeEntry.FileMode.Tree, sha: '6206dc5e7bcff5872a13c27f6ec490b1992f5f80', path: 'test' }
            ]
            encoding: 'utf8'
          )
          .expect('Content-Type', /json/)
          .expect(201, done)
