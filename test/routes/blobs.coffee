app = require('../../lib/server')
request = require('supertest')

describe 'blobs', ->
  describe 'show', ->
    uri = '/repos/gitdb/blobs/0c34a813091ad38eddff528c86e8d1b4f0a1c10b'
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