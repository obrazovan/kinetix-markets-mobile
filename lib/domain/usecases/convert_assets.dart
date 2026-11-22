import '../../core/errors/failures.dart';
import '../../core/utils/input_validator.dart';
import '../entities/conversion_result.dart';
import '../entities/convertible_instrument.dart';

/// Converts a positive amount between any two [ConvertibleInstrument]s via USD anchor.
class ConvertAssets {
  const ConvertAssets();

  ConversionResult call({
    required String rawAmount,
    required ConvertibleInstrument from,
    required ConvertibleInstrument to,
    required bool isOffline,
  }) {
    final validation = InputValidator.validateAmount(rawAmount);
    if (!validation.isValid || validation.parsedValue == null) {
      throw ValidationFailure(
        validation.errorMessage ?? 'Некорректная сумма',
      );
    }

    final amount = validation.parsedValue!;

    if (from.code == to.code) {
      return ConversionResult(
        amount: amount,
        fromInstrument: from,
        toInstrument: to,
        convertedAmount: amount,
        directRate: 1.0,
        inverseRate: 1.0,
        rateTimestamp: from.updatedAt,
        isSameAsset: true,
        isOffline: isOffline,
      );
    }

    if (from.usdPricePerUnit <= 0 || to.usdPricePerUnit <= 0) {
      throw const ValidationFailure(
        'Курс одного из выбранных активов недоступен',
      );
    }

    final directRate = from.usdPricePerUnit / to.usdPricePerUnit;
    final inverseRate = to.usdPricePerUnit / from.usdPricePerUnit;
    final convertedAmount = amount * directRate;

    final olderTimestamp = from.updatedAt.isBefore(to.updatedAt)
        ? from.updatedAt
        : to.updatedAt;

    return ConversionResult(
      amount: amount,
      fromInstrument: from,
      toInstrument: to,
      convertedAmount: convertedAmount,
      directRate: directRate,
      inverseRate: inverseRate,
      rateTimestamp: olderTimestamp,
      isSameAsset: false,
      isOffline: isOffline,
    );
  }
}
