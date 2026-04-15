import 'package:sanad_app/features/auth/models/auth_user.dart';

void main() {
  final user = AuthUser(
    uid: '123',
    email: 'test@test.com',
    displayName: 'Test User',
    phoneNumber: '12345678',
    createdAt: DateTime.now(),
    provider: AuthProvider.email,
    matchingPreferences: {
      'goals': ['ANXIETY'],
      'preferred_therapist_gender': 'any',
      'relationship_status': 'single',
      'medical_history': '',
    },
  );
  
  print('Percentage: ${user.profileCompletionPercentage}');
  
  final userEmptyMatching = AuthUser(
    uid: '123',
    email: 'test@test.com',
    displayName: 'Test User',
    phoneNumber: '12345678',
    createdAt: DateTime.now(),
    provider: AuthProvider.email,
    matchingPreferences: {},
  );
  
  print('Empty match map Percentage: ${userEmptyMatching.profileCompletionPercentage}');
}
