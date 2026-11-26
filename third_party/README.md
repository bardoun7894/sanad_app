# Vendored packages

Packages copied from pub.dev with a local patch, wired in through `dependency_overrides` in `pubspec.yaml`.

## zego_uikit_prebuilt_call 4.22.3

- Source: `~/.pub-cache/hosted/pub.dev/zego_uikit_prebuilt_call-4.22.3` (example/, doc/, documents/ dropped).
- Patch: `ios/Classes/ZegoUIKitCallPlugin.m` no longer calls `requestAuthorizationWithOptions` in
  `registerWithRegistrar`. Upstream asked for notification permission the moment the app launched,
  before onboarding and login. Sanad asks after login in `FCMService.requestPermission()`
  (`lib/features/auth/providers/auth_provider.dart`). The notification-center delegate is kept.
- Upgrading: copy the new version here, re-apply the patch (search for `SANAD PATCH`), and bump the
  `pubspec.yaml` constraint and override together.
