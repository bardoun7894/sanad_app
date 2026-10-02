#!/usr/bin/env node
'use strict';

// Run without --apply to inspect. Credentials remain outside the repository.
const fs = require('node:fs');
const crypto = require('node:crypto');
const apply = process.argv.includes('--apply');
const metadataOnly = process.argv.includes('--metadata-only');
const groupId = '22429209';
const plans = [
  { id: 'weekly', name: 'Weekly', period: 'ONE_WEEK', level: 4, price: '7.90', ar: 'الأسبوعية', fr: 'Hebdomadaire' },
  { id: 'basic', name: 'Basic', period: 'ONE_MONTH', level: 3, price: '19.90', ar: 'الأساسية', fr: 'Essentielle' },
  { id: 'premium', name: 'Premium', period: 'ONE_MONTH', level: 2, price: '34.90', ar: 'بريميوم', fr: 'Premium' },
  { id: 'premium_vip', name: 'Premium VIP', period: 'ONE_MONTH', level: 1, price: '54.90', ar: 'بريميوم VIP', fr: 'Premium VIP' },
];

async function main() {
  for (const name of ['ASC_KEY_ID', 'ASC_ISSUER_ID', 'ASC_KEY_PATH']) {
    if (!process.env[name]) throw new Error(`Missing ${name}`);
  }
  const key = fs.readFileSync(process.env.ASC_KEY_PATH);
  function token() {
    const now = Math.floor(Date.now() / 1000);
    const enc = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
    const input = enc({ alg: 'ES256', kid: process.env.ASC_KEY_ID, typ: 'JWT' }) + '.' +
      enc({ iss: process.env.ASC_ISSUER_ID, iat: now, exp: now + 600, aud: 'appstoreconnect-v1' });
    return input + '.' + crypto.sign('sha256', Buffer.from(input), { key, dsaEncoding: 'ieee-p1363' }).toString('base64url');
  }
  async function request(path, method = 'GET', data, allowMissing = false, attempt = 0) {
    const url = path.startsWith('https://') ? path : `https://api.appstoreconnect.apple.com${path}`;
    const response = await fetch(url, {
      method, headers: { Authorization: `Bearer ${token()}`, 'Content-Type': 'application/json' },
      ...(data ? { body: JSON.stringify({ data }) } : {}),
    });
    if ((response.status === 429 || (method === 'GET' && response.status >= 500)) && attempt < 6) {
      await response.arrayBuffer();
      const delay = Math.min(30000, 2000 * 2 ** attempt);
      await new Promise((resolve) => setTimeout(resolve, delay));
      return request(path, method, data, allowMissing, attempt + 1);
    }
    let body;
    try { body = await response.json(); }
    catch { throw new Error(`${method} ${path}: ${response.status}, non-JSON API response`); }
    if (allowMissing && response.status === 404 && body.errors?.every((e) => e.code === 'NOT_FOUND')) return { data: null };
    if (!response.ok) throw new Error(`${method} ${path}: ${response.status} ${JSON.stringify(body.errors)}`);
    return body;
  }
  async function list(path) {
    const rows = [];
    while (path) {
      const page = await request(path);
      rows.push(...page.data);
      path = page.links?.next;
    }
    return rows;
  }
  const relation = (type, id) => ({ data: { type, id } });
  const territories = apply ? await list('/v1/territories?limit=200') : [];
  const groupLocalizations = await list(`/v1/subscriptionGroups/${groupId}/subscriptionGroupLocalizations?limit=200`);
  if (apply) {
    for (const [locale, name] of [['en-US', 'Sanad Subscriptions'], ['ar-SA', 'اشتراكات سند'], ['fr-FR', 'Abonnements Sanad']]) {
      if (!groupLocalizations.some((l) => l.attributes.locale === locale)) await request('/v1/subscriptionGroupLocalizations', 'POST', {
        type: 'subscriptionGroupLocalizations', attributes: { locale, name },
        relationships: { subscriptionGroup: relation('subscriptionGroups', groupId) },
      });
    }
  }
  const existing = await list(`/v1/subscriptionGroups/${groupId}/subscriptions?limit=200`);
  for (const plan of plans) {
    const productId = `com.sanadtherapy.app.${plan.id}`;
    let subscription = existing.find((s) => s.attributes.productId === productId);
    if (!subscription && apply) {
      subscription = (await request('/v1/subscriptions', 'POST', {
        type: 'subscriptions', attributes: {
          name: `Sanad ${plan.name}`, productId, subscriptionPeriod: plan.period,
          familySharable: false, groupLevel: plan.level,
          reviewNote: 'In the app, sign in and open Subscription. Select this plan to purchase with the App Store. Restore Purchases and Manage Subscription are on the same screen. Access is verified by our server with StoreKit signed transactions.',
        }, relationships: { group: relation('subscriptionGroups', groupId) },
      })).data;
    }
    if (!subscription) { console.log(`${productId}: missing (would create ${plan.period}, USD ${plan.price})`); continue; }
    const id = subscription.id;
    if (subscription.attributes.subscriptionPeriod !== plan.period || subscription.attributes.groupLevel !== plan.level) {
      throw new Error(`${productId}: existing duration or rank differs from the plan; review before changing`);
    }
    if (apply) {
      const availability = await request(`/v1/subscriptions/${id}/subscriptionAvailability`, 'GET', undefined, true);
      if (!availability.data) await request('/v1/subscriptionAvailabilities', 'POST', {
        type: 'subscriptionAvailabilities', attributes: { availableInNewTerritories: true },
        relationships: {
          subscription: relation('subscriptions', id),
          availableTerritories: { data: territories.map((territory) => ({ type: 'territories', id: territory.id })) },
        },
      });
    }
    const localizations = await list(`/v1/subscriptions/${id}/subscriptionLocalizations?limit=200`);
    if (apply) {
      for (const [locale, name, description] of [
        ['en-US', `Sanad ${plan.name}`, plan.id === 'weekly' ? 'Weekly access to Sanad support features.' : 'Monthly access to Sanad support features.'],
        ['ar-SA', `سند ${plan.ar}`, plan.id === 'weekly' ? 'وصول أسبوعي إلى مميزات الدعم في سند.' : 'وصول شهري إلى مميزات الدعم في سند.'],
        ['fr-FR', `Sanad ${plan.fr}`, plan.id === 'weekly' ? 'Accès hebdomadaire aux fonctionnalités de Sanad.' : 'Accès mensuel aux fonctionnalités de Sanad.'],
      ]) {
        if (!localizations.some((l) => l.attributes.locale === locale)) {
          await request('/v1/subscriptionLocalizations', 'POST', {
            type: 'subscriptionLocalizations', attributes: { locale, name, description },
            relationships: { subscription: relation('subscriptions', id) },
          });
        }
      }
    }
    const prices = await list(`/v1/subscriptions/${id}/prices?include=territory,subscriptionPricePoint&limit=200`);
    const today = new Date().toISOString().slice(0, 10);
    const effectivePrices = prices.filter((price) =>
      price.attributes.preserved !== true &&
      (!price.attributes.startDate || price.attributes.startDate <= today) &&
      (!price.attributes.endDate || price.attributes.endDate > today));
    const usa = effectivePrices.find((price) => price.relationships?.territory?.data?.id === 'USA');
    const points = usa || (apply && !metadataOnly)
      ? await list(`/v1/subscriptions/${id}/pricePoints?filter[territory]=USA&limit=200`) : [];
    if (usa) {
      const point = points.find((point) => point.id === usa.relationships.subscriptionPricePoint.data.id);
      if (!point || Number(point.attributes.customerPrice) !== Number(plan.price)) {
        throw new Error(`${productId}: current USD price differs; review before changing`);
      }
    }
    if (apply && !metadataOnly) {
      const base = points.find((p) => Number(p.attributes.customerPrice) === Number(plan.price));
      if (!base) throw new Error(`Exact USD ${plan.price} price is unavailable for ${productId}`);
      const equalizations = await list(`/v1/subscriptionPricePoints/${base.id}/equalizations?include=territory&limit=200`);
      const all = [...new Map([base, ...equalizations].map((point) => [point.id, point])).values()];
      const priced = new Set(effectivePrices.map((price) => price.relationships?.subscriptionPricePoint?.data?.id));
      const missing = all.filter((point) => !priced.has(point.id));
      // Bound concurrency and recover from Apple's 429 responses when provisioning a large catalog.
      for (let offset = 0; offset < missing.length; offset += 2) {
        await Promise.all(missing.slice(offset, offset + 2).map(async (point) => {
          try { await request('/v1/subscriptionPrices', 'POST', {
          type: 'subscriptionPrices', attributes: { startDate: null, preserveCurrentPrice: true },
          relationships: {
            subscription: relation('subscriptions', id),
            subscriptionPricePoint: relation('subscriptionPricePoints', point.id),
          },
          }); } catch (error) { throw new Error(`${productId} / ${point.relationships.territory.data.id}: ${error.message}`); }
        }));
        if (offset + 2 < missing.length) await new Promise((resolve) => setTimeout(resolve, 700));
      }
      console.log(`${productId}: ${id}, localized, USD ${plan.price}, ${all.length} territories priced`);
    } else {
      console.log(`${productId}: ${id}, ${subscription.attributes.state}, ${localizations.length} localizations, ${prices.length} prices`);
    }
  }
}
main().catch((error) => { console.error(error.message); process.exitCode = 1; });
