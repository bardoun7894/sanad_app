/**
 * Unit tests for promptTemplates.js
 * Run: node --test functions/test/promptTemplates.test.js
 */

'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');

const { buildSystemPrompt, PERSONAS } = require('../lib/promptTemplates');

const sampleBriefing = {
  markdown: '## User Context\n- Name: Ahmed\n- Age: 28\n- Subscription: premium',
};

const samplePatterns = {
  trend: 'declining',
  dominantMood: 'sad',
  lowStreak: 3,
  weekendDip: true,
  noteThemes: ['work', 'sleep'],
  anomalies: [],
  riskLevel: 'moderate',
};

const sampleContent = [
  { id: 'c1', title: 'Breathing Exercise', type: 'exercise', reason: 'Matches your low mood' },
  { id: 'c2', title: 'تمرين التنفس', type: 'exercise', reason: 'مناسب لحالتك' },
];

test('buildSystemPrompt: returns a non-empty string', () => {
  const prompt = buildSystemPrompt({
    briefing: sampleBriefing,
    patterns: samplePatterns,
    content: sampleContent,
    locale: 'ar',
  });
  assert.ok(typeof prompt === 'string' && prompt.length > 0);
});

test('buildSystemPrompt: includes identity section', () => {
  const prompt = buildSystemPrompt({
    briefing: sampleBriefing,
    patterns: samplePatterns,
    content: sampleContent,
    locale: 'ar',
  });
  assert.ok(prompt.includes('Sanad') || prompt.includes('سند'), 'Should contain identity (Sanad/سند)');
});

test('buildSystemPrompt: includes briefing markdown block', () => {
  const prompt = buildSystemPrompt({
    briefing: sampleBriefing,
    patterns: samplePatterns,
    content: sampleContent,
    locale: 'ar',
  });
  assert.ok(prompt.includes('User Context') || prompt.includes('سياق'), 'Should contain briefing block');
});

test('buildSystemPrompt: includes detected patterns section', () => {
  const prompt = buildSystemPrompt({
    briefing: sampleBriefing,
    patterns: samplePatterns,
    content: sampleContent,
    locale: 'ar',
  });
  assert.ok(prompt.includes('declining') || prompt.includes('patterns') || prompt.includes('أنماط'), 'Should contain patterns section');
});

test('buildSystemPrompt: includes recommended content section', () => {
  const prompt = buildSystemPrompt({
    briefing: sampleBriefing,
    patterns: samplePatterns,
    content: sampleContent,
    locale: 'ar',
  });
  assert.ok(
    prompt.includes('Breathing Exercise') || prompt.includes('تمرين'),
    'Should contain content recommendations'
  );
});

test('buildSystemPrompt: AR locale includes Arabic footer instruction', () => {
  const prompt = buildSystemPrompt({
    briefing: sampleBriefing,
    patterns: samplePatterns,
    content: sampleContent,
    locale: 'ar',
  });
  assert.ok(prompt.includes('أجب') || prompt.includes('Arabic') || prompt.includes('العربية'), 'AR locale should include Arabic instruction');
});

test('buildSystemPrompt: EN locale includes English footer instruction', () => {
  const prompt = buildSystemPrompt({
    briefing: sampleBriefing,
    patterns: samplePatterns,
    content: sampleContent,
    locale: 'en',
  });
  assert.ok(
    prompt.includes("Answer in") || prompt.includes("English") || prompt.includes("language"),
    'EN locale should include English instruction'
  );
});

test('buildSystemPrompt: FR locale includes French footer instruction', () => {
  const prompt = buildSystemPrompt({
    briefing: sampleBriefing,
    patterns: samplePatterns,
    content: sampleContent,
    locale: 'fr',
  });
  assert.ok(
    prompt.includes("Répondez") || prompt.includes("français") || prompt.includes("French"),
    'FR locale should include French instruction'
  );
});

test('buildSystemPrompt: includes crisis protocol', () => {
  const prompt = buildSystemPrompt({
    briefing: sampleBriefing,
    patterns: samplePatterns,
    content: sampleContent,
    locale: 'ar',
  });
  assert.ok(
    prompt.includes('CRISIS') || prompt.includes('crisis') || prompt.includes('أزمة') || prompt.includes('920033360'),
    'Should contain crisis protocol'
  );
});

test('buildSystemPrompt: empty content list still works', () => {
  const prompt = buildSystemPrompt({
    briefing: sampleBriefing,
    patterns: samplePatterns,
    content: [],
    locale: 'ar',
  });
  assert.ok(typeof prompt === 'string' && prompt.length > 0);
});

// ── PERSONAS ────────────────────────────────────────────────────────────────────

test('PERSONAS: exports an object', () => {
  assert.ok(PERSONAS !== null && typeof PERSONAS === 'object');
});

test('PERSONAS: has exactly 5 required keys', () => {
  const required = ['companion', 'coach', 'cbt_therapist', 'mindfulness_guide', 'crisis_companion'];
  for (const key of required) {
    assert.ok(key in PERSONAS, `Missing persona: ${key}`);
  }
  assert.equal(Object.keys(PERSONAS).length, 5);
});

test('PERSONAS: each persona has ar, en, fr keys all non-empty', () => {
  for (const [id, persona] of Object.entries(PERSONAS)) {
    assert.ok(typeof persona.ar === 'string' && persona.ar.length > 0, `${id}.ar empty`);
    assert.ok(typeof persona.en === 'string' && persona.en.length > 0, `${id}.en empty`);
    assert.ok(typeof persona.fr === 'string' && persona.fr.length > 0, `${id}.fr empty`);
  }
});

test('buildSystemPrompt: cbt_therapist persona injects Mode header in en', () => {
  const prompt = buildSystemPrompt({
    briefing: sampleBriefing,
    patterns: samplePatterns,
    content: sampleContent,
    locale: 'en',
    persona: 'cbt_therapist',
  });
  assert.ok(prompt.includes('## Mode: cbt_therapist'), 'Should include Mode header');
  assert.ok(prompt.includes(PERSONAS.cbt_therapist.en), 'Should include en CBT overlay');
});

test('buildSystemPrompt: Mode header appears after app-features and before USER CONTEXT', () => {
  const prompt = buildSystemPrompt({
    briefing: sampleBriefing,
    patterns: samplePatterns,
    content: sampleContent,
    locale: 'en',
    persona: 'coach',
  });
  const identityIdx = prompt.indexOf('# IDENTITY');
  const modeIdx = prompt.indexOf('## Mode:');
  const userCtxIdx = prompt.indexOf('USER CONTEXT');
  assert.ok(identityIdx !== -1, 'IDENTITY section must exist');
  assert.ok(modeIdx !== -1, 'Mode header must exist');
  assert.ok(userCtxIdx !== -1, 'USER CONTEXT section must exist');
  assert.ok(modeIdx > identityIdx, 'Mode must come after IDENTITY');
  assert.ok(modeIdx < userCtxIdx, 'Mode must come before USER CONTEXT');
});

test('buildSystemPrompt: unknown persona falls back to companion', () => {
  const prompt = buildSystemPrompt({
    briefing: sampleBriefing,
    patterns: samplePatterns,
    content: sampleContent,
    locale: 'en',
    persona: 'bogus_persona_xyz',
  });
  // Should use companion overlay, not throw
  assert.ok(typeof prompt === 'string' && prompt.length > 0);
  assert.ok(prompt.includes('## Mode: companion'), 'Unknown persona should fall back to companion');
  assert.ok(prompt.includes(PERSONAS.companion.en), 'Should include companion en overlay');
});

test('buildSystemPrompt: default (no persona arg) uses companion', () => {
  const prompt = buildSystemPrompt({
    briefing: sampleBriefing,
    patterns: samplePatterns,
    content: sampleContent,
    locale: 'en',
  });
  assert.ok(prompt.includes('## Mode: companion'), 'Default should use companion mode');
});

test('buildSystemPrompt: persona uses correct locale overlay (ar)', () => {
  const prompt = buildSystemPrompt({
    briefing: sampleBriefing,
    patterns: samplePatterns,
    content: sampleContent,
    locale: 'ar',
    persona: 'mindfulness_guide',
  });
  assert.ok(prompt.includes(PERSONAS.mindfulness_guide.ar), 'Should include ar mindfulness overlay');
});

test('buildSystemPrompt: persona uses correct locale overlay (fr)', () => {
  const prompt = buildSystemPrompt({
    briefing: sampleBriefing,
    patterns: samplePatterns,
    content: sampleContent,
    locale: 'fr',
    persona: 'crisis_companion',
  });
  assert.ok(prompt.includes(PERSONAS.crisis_companion.fr), 'Should include fr crisis overlay');
});
