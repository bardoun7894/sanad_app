'use strict';

/**
 * contentMatcher.js — Content matching based on mood patterns for Sanad AI.
 *
 * Firestore schema (confirmed from lib/features/content/models/content_models.dart):
 *   content/{docId}: {
 *     title: string (AR), title_en: string (EN),
 *     type: 'article'|'exercise'|'podcast'|'video',
 *     moodTags: string[],
 *     isPremium: bool,
 *     isPublished: bool,
 *     media_url | link_url | content_url: string?
 *   }
 */

/**
 * Match content items to user patterns.
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {{ dominantMood: string|null, noteThemes: string[], riskLevel: string }} patterns
 * @param {string} locale - 'ar' | 'en' | 'fr'
 * @param {string|null} subscriptionState - 'free', 'premium', etc.
 * @param {number} limit
 * @returns {Promise<Array<{id, title, type, contentUrl, reason}>>}
 */
async function matchContent(db, patterns, locale = 'ar', subscriptionState = null, limit = 5) {
  // Build candidate tags: dominant mood + note themes
  const tags = [];
  if (patterns.dominantMood) {
    tags.push(patterns.dominantMood);
  }
  if (patterns.noteThemes && patterns.noteThemes.length > 0) {
    tags.push(...patterns.noteThemes);
  }

  if (tags.length === 0) {
    // Fallback: return recently published content
    return _fallbackContent(db, locale, subscriptionState, limit);
  }

  // array-contains-any supports up to 10 values
  const queryTags = tags.slice(0, 10);
  let query = db.collection('content')
    .where('isPublished', '==', true)
    .where('moodTags', 'array-contains-any', queryTags)
    .limit(limit * 3); // over-fetch to allow premium filtering

  const snap = await query.get();

  const isPremium = subscriptionState === 'active' || subscriptionState === 'premium';

  const results = [];
  for (const doc of snap.docs) {
    const d = doc.data();
    if (d.isPremium && !isPremium) continue; // exclude premium for non-premium users
    if (results.length >= limit) break;

    const title = locale === 'en'
      ? (d.title_en || d.title || '')
      : (d.title || d.title_en || '');

    const contentUrl = d.media_url || d.link_url || d.content_url || null;

    // Build reason string
    let reason = '';
    if (patterns.dominantMood && d.moodTags && d.moodTags.includes(patterns.dominantMood)) {
      reason = locale === 'ar'
        ? `يناسب حالتك المزاجية: ${patterns.dominantMood}`
        : `Matches your ${patterns.dominantMood} mood pattern`;
    } else if (patterns.noteThemes && patterns.noteThemes.length > 0) {
      const matchedTheme = patterns.noteThemes.find(t => d.moodTags && d.moodTags.includes(t));
      if (matchedTheme) {
        reason = locale === 'ar'
          ? `يرتبط بما تكتب عنه: ${matchedTheme}`
          : `Related to your notes about ${matchedTheme}`;
      }
    }
    if (!reason) {
      reason = locale === 'ar' ? 'محتوى موصى به' : 'Recommended for you';
    }

    results.push({
      id: doc.id,
      title,
      type: d.type || 'article',
      contentUrl,
      reason,
    });
  }

  if (results.length === 0) {
    return _fallbackContent(db, locale, subscriptionState, limit);
  }

  return results;
}

/**
 * Fallback: return recently published content when no mood tags match.
 */
async function _fallbackContent(db, locale, subscriptionState, limit) {
  const isPremium = subscriptionState === 'active' || subscriptionState === 'premium';
  const snap = await db.collection('content')
    .where('isPublished', '==', true)
    .orderBy('createdAt', 'desc')
    .limit(limit * 2)
    .get();

  const results = [];
  for (const doc of snap.docs) {
    const d = doc.data();
    if (d.isPremium && !isPremium) continue;
    if (results.length >= limit) break;
    const title = locale === 'en'
      ? (d.title_en || d.title || '')
      : (d.title || d.title_en || '');
    results.push({
      id: doc.id,
      title,
      type: d.type || 'article',
      contentUrl: d.media_url || d.link_url || d.content_url || null,
      reason: locale === 'ar' ? 'محتوى عام موصى به' : 'General recommendation',
    });
  }
  return results;
}

module.exports = { matchContent };
