import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/services/gemini_service.dart';

void main() {
  test('detects depleted AI Studio prepaid credit', () {
    expect(
      isAiBillingExhaustedError(GeminiException(
          'Unexpected error: GenerativeAIException: Your prepayment credits are depleted.')),
      isTrue,
    );
    expect(isAiBillingExhaustedError(Exception('HTTP 402 Payment Required')), isTrue);
  });

  test('other errors are not billing errors', () {
    expect(isAiBillingExhaustedError(GeminiException('Empty response from AI')), isFalse);
    expect(isAiBillingExhaustedError(Exception('network down')), isFalse);
  });
}
