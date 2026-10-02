import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/auth/utils/profile_completion_requirements.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  const basicFields = {
    ProfileField.firstName,
    ProfileField.lastName,
    ProfileField.phone,
    ProfileField.email,
  };

  Set<ProfileField> missing(Set<ProfileField> filled, {bool isWeb = false}) =>
      missingProfileFields(
        platform: defaultTargetPlatform,
        isWeb: isWeb,
        filled: filled,
      );

  test(
    'iOS completes with only first and last name, valid phone and email',
    () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(missing(basicFields), isEmpty);
    },
  );

  test('iOS requires both names, valid phone and valid email', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    for (final field in basicFields) {
      expect(missing({...basicFields}..remove(field)), {field});
    }
  });

  test(
    'Android still rejects an otherwise complete profile without gender',
    () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(missing({...ProfileField.values}..remove(ProfileField.gender)), {
        ProfileField.gender,
      });
      expect(missing(basicFields), contains(ProfileField.gender));
    },
  );

  test('Android keeps email optional and all previous fields required', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(
      missing({...ProfileField.values}..remove(ProfileField.email)),
      isEmpty,
    );
    for (final field in ProfileField.values.where(
      (f) => f != ProfileField.email,
    )) {
      expect(missing({...ProfileField.values}..remove(field)), {field});
    }
  });

  test('web keeps the full requirements even with an iOS target', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(missing(basicFields, isWeb: true), contains(ProfileField.gender));
    expect(
      missing(
        {...ProfileField.values}..remove(ProfileField.email),
        isWeb: true,
      ),
      isEmpty,
    );
  });
}
