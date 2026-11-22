import 'convertible_instrument.dart';

/// Output of converting a positive amount between two market instruments.
class ConversionResult {
  const ConversionResult({
    required this.amount,
    required this.fromInstrument,
    required this.toInstrument,
    required this.convertedAmount,
    required this.directRate,
    required this.inverseRate,
    required this.rateTimestamp,
    required this.isSameAsset,
    required this.isOffline,
  });

  final double amount;
  final ConvertibleInstrument fromInstrument;
  final ConvertibleInstrument toInstrument;
  final double convertedAmount;
  final double directRate;
  final double inverseRate;
  final DateTime rateTimestamp;
  final bool isSameAsset;
  final bool isOffline;
}
