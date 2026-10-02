#!/usr/bin/env node
'use strict';
const fs = require('node:fs');
const { AppStoreServerAPIClient, Environment } = require('../functions/node_modules/@apple/app-store-server-library');

async function main() {
  for (const name of ['APP_STORE_KEY_PATH', 'APP_STORE_KEY_ID', 'APP_STORE_ISSUER_ID']) {
    if (!process.env[name]) throw new Error(`Missing ${name}`);
  }
  const key = fs.readFileSync(process.env.APP_STORE_KEY_PATH, 'utf8');
  for (const environment of [Environment.SANDBOX, Environment.PRODUCTION]) {
    const client = new AppStoreServerAPIClient(key, process.env.APP_STORE_KEY_ID,
      process.env.APP_STORE_ISSUER_ID, 'com.sanadtherapy.app', environment);
    const { testNotificationToken } = await client.requestTestNotification();
    let delivered = false;
    for (let attempt = 0; attempt < 12; attempt++) {
      await new Promise((resolve) => setTimeout(resolve, 5000));
      const status = await client.getTestNotificationStatus(testNotificationToken);
      const attempts = status.sendAttempts || [];
      if (attempts.length) console.log(JSON.stringify({ environment, attempts }));
      if (attempts.some((item) => item.sendAttemptResult === 'SUCCESS')) { delivered = true; break; }
    }
    if (!delivered) throw new Error(`${environment}: Apple test notification did not succeed`);
  }
}
main().catch((error) => {
  console.error(JSON.stringify({ message: error.message, httpStatusCode: error.httpStatusCode, apiError: error.apiError }));
  process.exitCode = 1;
});
