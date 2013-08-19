app = require('../../lib/app')
request = require('supertest')
git = require('nodegit')

describe 'commits', ->
  describe 'index', ->
    uri = '/repos/gitdb/refs/heads/master/commits'
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
    uri = '/repos/gitdb/commits/a4fd4d1b5368664ee291adf539db0ba40935df5b'
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
    uri = '/repos/gitdb/commits'
    describe 'json', ->
      it 'works', (done) ->
        request(app)
          .put(uri)
          .set('Accept', 'application/json')
          .send(
            message: 'Get on the bus, gus'
            parents: ['a4fd4d1b5368664ee291adf539db0ba40935df5b']
            tree: [
              path: 'README.md'
              content: 'Get on the bus, Gus'
              filemode: git.TreeEntry.FileMode.Blob
            ]
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
