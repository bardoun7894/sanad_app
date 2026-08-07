# Play Store publishing — one-time setup

Automated releases need a Google Play **service account** with the Release
manager role. This is the only step that can't be scripted: it requires an
account owner signed into Play Console.

## 1. Create the service account

1. [Play Console](https://play.google.com/console) → **Setup → API access**
   (left sidebar, under the account-level menu — not inside the app).
2. If prompted, link a Google Cloud project. Any project works; reusing the
   Firebase project `sanad-app-beldify` keeps things in one place.
3. Under *Service accounts*, click **Create new service account**. That opens
   Google Cloud Console in a new tab.
4. In Cloud Console: **Create service account** → name it `play-publisher` →
   **Done**. No Cloud IAM roles are needed; permissions come from Play.
5. Open the new account → **Keys** → **Add key → Create new key → JSON**.
   The file downloads immediately. It is a credential — treat it like a
   password.
6. Back in Play Console → **API access** → **Refresh service accounts** → find
   `play-publisher` → **Grant access**.
7. Permissions: **App permissions** → select *Sanad*. **Account permissions** →
   tick **Releases: Release apps to testing tracks** and **Release apps to
   production**. → **Invite user** → **Send invite**.

Play takes a few minutes to propagate the grant.

## 2. Install the key

```bash
mv ~/Downloads/<downloaded>.json \
   /Users/mohamedbardouni/projects/sanad_app/android/fastlane/play-service-account.json
chmod 600 android/fastlane/play-service-account.json
```

It is gitignored — never commit it.

## 3. Verify before shipping

```bash
cd android && fastlane check
```

Prints the versionCodes currently live on Production. If this fails, the grant
hasn't propagated or the permissions are wrong — fix that before uploading.

## Releasing

```bash
# from repo root: bump `version:` in pubspec.yaml first (versionCode must be new)
cd android

fastlane build                      # signed AAB from the current pubspec version
fastlane internal                   # → Internal testing, live in minutes
fastlane production                 # → Production, full rollout
fastlane production rollout:0.1     # → Production, staged 10% rollout
```

## Gotchas

- **versionCode must always increase.** Play permanently rejects a code it has
  already accepted, even for a deleted draft. `1.0.20+44` → versionCode 44.
- **Signing** uses `android/key.properties` (the UPLOAD key). Play re-signs with
  the app signing key. Losing the upload key means asking Google to reset it.
- **Force-update gate**: only raise `min_app_version` in the admin dashboard
  *after* the build is live on Play, or you lock existing users out of the app.
- Metadata/screenshots are deliberately skipped, so a release never overwrites
  the store listing.
