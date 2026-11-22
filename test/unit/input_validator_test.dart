import 'package:flutter_test/flutter_test.dart';
import 'package:kinetix_markets/core/utils/input_validator.dart';

void main() {
  group('InputValidator', () {
    test('accepts positive numbers with dot or comma decimal separators', () {
      expect(InputValidator.validateAmount('100').parsedValue, 100.0);
      expect(InputValidator.validateAmount('125,50').parsedValue, 125.5);
      expect(InputValidator.validateAmount(' 0.0025 ').parsedValue, 0.0025);
      expect(InputValidator.validateAmount('1 500,75').parsedValue, 1500.75);
    });

    test('rejects empty, zero, negative, non-numeric, and overflow values', () {
      expect(InputValidator.validateAmount('').isValid, isFalse);
      expect(InputValidator.validateAmount('   ').isValid, isFalse);
      expect(InputValidator.validateAmount('0').isValid, isFalse);
      expect(InputValidator.validateAmount('0.00').isValid, isFalse);
      expect(InputValidator.validateAmount('-15').isValid, isFalse);
      expect(InputValidator.validateAmount('abc').isValid, isFalse);
      expect(InputValidator.validateAmount('12.3.4').isValid, isFalse);
      expect(InputValidator.validateAmount('NaN').isValid, isFalse);
      expect(InputValidator.validateAmount('999999999999999999').isValid, isFalse);
    });
  });
}
