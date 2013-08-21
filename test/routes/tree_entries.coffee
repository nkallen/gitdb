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
              .send(
                message: 'A new idea for a song lyric ' + new Date()
                previous_sha: previousSha
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
