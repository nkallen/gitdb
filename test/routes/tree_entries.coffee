app = require('../../lib/app')
request = require('supertest')

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