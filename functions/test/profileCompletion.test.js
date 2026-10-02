const test = require('node:test');
const assert = require('node:assert');
const { isMandatoryProfileComplete } = require('../lib/profileCompletion');

const full = {
  first_name: 'Sara', phone: '+249912345678', gender: 'female',
  date_of_birth: new Date('1990-01-01'), avatar_url: 'assets/a.png',
  matching_preferences: { goals: ['anxiety'], relationship_status: 'single', preferred_therapist_gender: 'any' },
};

test('android/legacy profile needs the full mandatory set', () => {
  assert.equal(isMandatoryProfileComplete(full), true);
  assert.equal(isMandatoryProfileComplete({ ...full, gender: '' }), false);
  assert.equal(isMandatoryProfileComplete({ first_name: 'Sara', phone: '+249912345678', email: 'a@b.co' }), false);
});

test('iOS profile needs only name, phone and email', () => {
  const ios = { profile_platform: 'ios', first_name: 'Sara', phone: '+249912345678', email: 'sara@example.com' };
  assert.equal(isMandatoryProfileComplete(ios), true);
  assert.equal(isMandatoryProfileComplete({ ...ios, email: '' }), false);
  assert.equal(isMandatoryProfileComplete({ ...ios, phone: '', whatsapp_number: '' }), false);
});

test('placeholder names do not count', () => {
  const ios = { profile_platform: 'ios', first_name: 'User', phone: '+249912345678', email: 'sara@example.com' };
  assert.equal(isMandatoryProfileComplete(ios), false);
});
