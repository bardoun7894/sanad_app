/**
 * Single source of truth for "is this user's mandatory profile filled in".
 *
 * iOS profiles (profile_platform === 'ios') only require name, phone and email:
 * App Review rejects apps that force personal data the service does not need
 * (Guideline 5.1.1), so the owner asked for a minimal iPhone signup. Every
 * other profile keeps the full set the Android wizard collects.
 */
const str = (v) => (v == null ? '' : String(v).trim());

// 'User'/'مستخدم' are placeholder names seeded for nameless signups.
const realName = (v) => {
  const t = str(v).toLowerCase();
  return !!t && t !== 'user' && t !== 'مستخدم';
};

function isMandatoryProfileComplete(d) {
  if (!d) return false;
  const hasName = realName(d.first_name) || realName(d.display_name) || realName(d.name);
  // whatsapp_number is an acceptable contact fallback.
  const hasPhone = !!str(d.phone) || !!str(d.whatsapp_number);
  if (d.profile_platform === 'ios') {
    return hasName && hasPhone && !!str(d.email);
  }
  const mp = d.matching_preferences || {};
  return (
    hasName &&
    hasPhone &&
    !!str(d.gender) &&
    !!d.date_of_birth &&
    !!str(d.avatar_url) &&
    Array.isArray(mp.goals) && mp.goals.length > 0 &&
    !!str(mp.relationship_status) &&
    !!str(mp.preferred_therapist_gender)
  );
}

module.exports = { isMandatoryProfileComplete };
