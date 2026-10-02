import 'package:flutter/foundation.dart';

enum ProfileField {
  firstName,
  lastName,
  phone,
  email,
  whatsapp,
  avatar,
  dateOfBirth,
  gender,
  goals,
  preferredGender,
  relationship,
  medicalHistory,
}

/// [filled] contains fields whose values have passed their input validation.
Set<ProfileField> missingProfileFields({
  required TargetPlatform platform,
  required bool isWeb,
  required Set<ProfileField> filled,
}) {
  final requiredFields = !isWeb && platform == TargetPlatform.iOS
      ? {
          ProfileField.firstName,
          ProfileField.lastName,
          ProfileField.phone,
          ProfileField.email,
        }
      : ({...ProfileField.values}..remove(ProfileField.email));
  return requiredFields.difference(filled);
}
