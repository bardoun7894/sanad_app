/**
 * Notifications written without an action_route are deleted by older app
 * builds on open. Give them a default route so they stay in the bell.
 */
const DEFAULT_NOTIFICATION_ROUTE = '/notifications';

function needsDefaultRoute(data) {
  const r = data ? data.action_route : undefined;
  return r == null || String(r).trim() === '';
}

module.exports = { needsDefaultRoute, DEFAULT_NOTIFICATION_ROUTE };
