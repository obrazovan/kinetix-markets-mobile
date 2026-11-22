/// Result of validating a user-entered monetary or asset amount.
class InputValidationResult {
  const InputValidationResult._({
    required this.isValid,
    this.parsedValue,
    this.errorMessage,
  });

  const InputValidationResult.valid(double value)
      : this._(isValid: true, parsedValue: value);

  const InputValidationResult.invalid(String message)
      : this._(isValid: false, errorMessage: message);

  final bool isValid;
  final double? parsedValue;
  final String? errorMessage;
}

/// Validates numeric user inputs across conversion and analytics controls.
abstract final class InputValidator {
  static const double maxAllowedAmount = 1e15;
  static final RegExp _numericPattern = RegExp(r'^[+-]?(\d+(\.\d*)?|\.\d+)$');

  /// Validates and parses positive numeric amounts supporting `.` and `,`.
  static InputValidationResult validateAmount(String raw) {
    final trimmed = raw.trim().replaceAll(' ', '').replaceAll('\u00A0', '');
    if (trimmed.isEmpty) {
      return const InputValidationResult.invalid(
        'Введите сумму для расчёта',
      );
    }

    final normalized = trimmed.replaceAll(',', '.');
    if (!_numericPattern.hasMatch(normalized)) {
      return const InputValidationResult.invalid(
        'Некорректный числовой формат',
      );
    }

    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) {
      return const InputValidationResult.invalid(
        'Невозможно распознать число',
      );
    }

    if (parsed <= 0) {
      return const InputValidationResult.invalid(
        'Сумма должна быть строго больше нуля',
      );
    }

    if (parsed > maxAllowedAmount) {
      return const InputValidationResult.invalid(
        'Сумма превышает допустимый предел',
      );
    }

    return InputValidationResult.valid(parsed);
  }
}
