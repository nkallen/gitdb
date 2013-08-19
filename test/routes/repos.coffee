app = require('../../lib/app')
request = require('supertest')
git = require('nodegit')

describe 'repos', ->
  describe 'index', ->

  describe 'show', ->
    uri = '/repos/gitdb'
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
