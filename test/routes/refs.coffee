app = require('../../lib/server')
request = require('supertest')
git = require('nodegit')

describe 'refs', ->
  describe 'index', ->
    uri = '/repos/gitdb/refs'
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

  describe 'show', ->
    uri = '/repos/gitdb/refs/heads/master'
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

  describe 'create', ->
