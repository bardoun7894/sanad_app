import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/admin/providers/admin_provider.dart';

void main() {
  test('isDemoUser flags only is_demo == true', () {
    expect(isDemoUser({'is_demo': true, 'is_premium': true}), isTrue);
    expect(isDemoUser({'is_demo': false}), isFalse);
    expect(isDemoUser({'is_premium': true}), isFalse);
    expect(isDemoUser({'is_demo': 'true'}), isFalse);
  });
}
