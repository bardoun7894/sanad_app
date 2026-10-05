const test = require('node:test');
const assert = require('node:assert');
const { needsDefaultRoute, DEFAULT_NOTIFICATION_ROUTE } = require('../lib/notificationRoute');

test('empty routes need the default', () => {
  assert.equal(needsDefaultRoute({ action_route: null }), true);
  assert.equal(needsDefaultRoute({ action_route: undefined }), true);
  assert.equal(needsDefaultRoute({ action_route: '' }), true);
  assert.equal(needsDefaultRoute({ action_route: '  ' }), true);
  assert.equal(needsDefaultRoute({}), true);
});

test('existing route is kept', () => {
  assert.equal(needsDefaultRoute({ action_route: '/article/x' }), false);
});

test('default route value', () => {
  assert.equal(DEFAULT_NOTIFICATION_ROUTE, '/notifications');
});
