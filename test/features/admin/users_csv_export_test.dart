import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/admin/providers/admin_users_provider.dart';
import 'package:sanad_app/features/admin/utils/users_csv.dart';

/// Unit tests for the pure users-CSV builder.
/// Never calls DateTime.now() — all dates are fixed values. The browser
/// download side-effect is NOT tested here (Flutter web only).
void main() {
  final named = AdminUser(
    id: 'u1',
    email: 'fahad@example.com',
    displayName: 'فهد القحطاني',
    isPremium: true,
    subscriptionStatus: 'active',
    role: 'user',
    phoneNumber: '+966500000001',
    whatsappNumber: '+966500000002',
    gender: 'male',
    assignedTherapistName: 'Lamia Salah',
    authProvider: 'password',
    hasCompleteProfile: true,
    createdAt: DateTime(2026, 5, 17),
  );

  // Phone-only signup: no name, "No Email" placeholder.
  final phoneOnly = AdminUser(
    id: 'u2',
    email: 'No Email',
    phoneNumber: '+966500000099',
    createdAt: DateTime(2026, 6, 1),
  );

  test('starts with UTF-8 BOM and Arabic header row', () {
    final csv = buildUsersCsv([named]);
    expect(csv.codeUnitAt(0), 0xFEFF); // BOM
    final headerLine = csv.split('\n')[0];
    expect(headerLine, contains('الاسم'));
    expect(headerLine, contains('الهاتف'));
    expect(headerLine, contains('تاريخ التسجيل'));
  });

  test('emits one data row per user with resolved fields', () {
    final csv = buildUsersCsv([named]);
    expect(csv, contains('فهد القحطاني'));
    expect(csv, contains('fahad@example.com'));
    expect(csv, contains('+966500000001'));
    expect(csv, contains('مدفوع')); // isPremium -> paid
    expect(csv, contains('Lamia Salah'));
    expect(csv, contains('2026-05-17'));
    expect(csv, contains('نعم')); // complete profile
  });

  test('normalises "No Email" placeholder to an empty cell', () {
    final csv = buildUsersCsv([phoneOnly]);
    expect(csv, isNot(contains('No Email')));
    expect(csv, contains('+966500000099'));
    expect(csv, contains('مجاني')); // free
  });

  test('a field containing a comma is RFC-4180 quoted', () {
    final commaUser = AdminUser(
      id: 'u3',
      email: 'x@y.com',
      displayName: 'Smith, John',
    );
    final csv = buildUsersCsv([commaUser]);
    expect(csv, contains('"Smith, John"'));
  });
}
