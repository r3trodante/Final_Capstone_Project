const http = require('http');
const supertest = require('supertest');
const { expect } = require('chai');

let server;

before(() => {
  const app = require('../index'); // We'll export the server instance below
  server = app;
});

after(() => {
  server.close();
});

describe('GET /', () => {
  it('should return 200 OK and contain the expected message', (done) => {
    supertest(server)
      .get('/')
      .expect(200)
      .end((err, res) => {
        expect(res.text).to.include('Congratulations from EMC Node.js App');
        done(err);
      });
  });
});
