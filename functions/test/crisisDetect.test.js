const test = require('node:test');
const assert = require('node:assert');
const {
  detectCrisis, isDuplicateAlert, contactOf, buildCrisisAdminMessage,
} = require('../lib/crisisDetect');

test('flags MSA and dialect suicidal messages', () => {
  for (const msg of [
    'كيف اخفف أفكار الانتحار',
    'عندي أفكار انتحارية',
    'بفكر أنتحر والله',
    'أنا عايزة أموت',
    'داير اموت ما قادر',
    'ابي اموت',
    'بدي موت',
    'ما عايز أعيش تاني',
    'بفكر أأذي نفسي',
    'I want to kill myself',
    'having suicidal thoughts',
    "j'ai envie de mourir",
  ]) {
    assert.ok(detectCrisis(msg).isCrisis, msg);
  }
});

test('ignores harakat and tatweel', () => {
  assert.ok(detectCrisis('أُرِيدُ الْمَوْتَ').isCrisis);
  assert.ok(detectCrisis('انتـــحار').isCrisis);
});

test('does not flag ordinary messages', () => {
  for (const msg of ['أنا متضايق من الشغل', 'نفسي ارسل الدردشه', 'how do I book a coach', 'je suis fatigué', '']) {
    assert.strictEqual(detectCrisis(msg).isCrisis, false, msg);
  }
});

test('duplicate = same normalized text within 10 minutes', () => {
  const now = Date.now();
  const recent = [{ triggered_text: 'عندي أفكار انتحارية', created_at: { toMillis: () => now - 60_000 } }];
  assert.ok(isDuplicateAlert(recent, 'عندي افكار انتحاريه', now));
  assert.strictEqual(isDuplicateAlert(recent, 'رسالة أخرى عن الانتحار', now), false);
  const old = [{ triggered_text: 'عندي أفكار انتحارية', created_at: { toMillis: () => now - 11 * 60_000 } }];
  assert.strictEqual(isDuplicateAlert(old, 'عندي أفكار انتحارية', now), false);
});

test('admin message carries name, phone, email and the text', () => {
  const contact = contactOf({ name: 'Zeinab', phone: '+249995322331', email: 'z@example.com' });
  const m = buildCrisisAdminMessage({ contact, text: 'عندي أفكار انتحارية' });
  assert.match(m.body, /Zeinab/);
  assert.match(m.body, /\+249995322331/);
  assert.match(m.body, /z@example\.com/);
  assert.match(m.body, /عندي أفكار انتحارية/);
  assert.match(m.bodyEn, /\+249995322331/);
});

test('contactOf falls back to first/last name and phone_number', () => {
  assert.deepStrictEqual(
    contactOf({ first_name: 'A', last_name: 'B', phone_number: '+1' }),
    { name: 'A B', phone: '+1', email: '' },
  );
});
