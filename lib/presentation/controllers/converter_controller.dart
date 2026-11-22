import 'package:flutter/foundation.dart';

import '../../core/errors/failures.dart';
import '../../core/utils/input_validator.dart';
import '../../domain/entities/conversion_result.dart';
import '../../domain/entities/convertible_instrument.dart';
import '../../domain/entities/market_snapshot.dart';
import '../../domain/usecases/convert_assets.dart';

/// State controller for cross-asset conversion with real-time validation.
class ConverterController extends ChangeNotifier {
  ConverterController({required ConvertAssets convertAssets})
      : _convertAssets = convertAssets;

  final ConvertAssets _convertAssets;

  List<ConvertibleInstrument> _catalog = const [];
  String _fromCode = 'USD';
  String _toCode = 'MDL';
  String _rawAmount = '100';
  InputValidationResult _validation = const InputValidationResult.valid(100);
  ConversionResult? _result;
  String? _errorMessage;
  bool _isOffline = false;

  List<ConvertibleInstrument> get catalog => _catalog;
  String get fromCode => _fromCode;
  String get toCode => _toCode;
  String get rawAmount => _rawAmount;
  InputValidationResult get validation => _validation;
  ConversionResult? get result => _result;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;

  bool get canConvert =>
      _validation.isValid &&
      fromInstrument != null &&
      toInstrument != null;

  ConvertibleInstrument? get fromInstrument => _findByCode(_fromCode);
  ConvertibleInstrument? get toInstrument => _findByCode(_toCode);

  void syncSnapshot(MarketSnapshot? snapshot) {
    if (snapshot == null || snapshot.assets.isEmpty) return;
    _isOffline = snapshot.isOffline;
    _catalog = ConvertibleInstrument.catalogFromSnapshot(snapshot);

    if (fromInstrument == null && _catalog.isNotEmpty) {
      _fromCode = _catalog.first.code;
    }
    if (toInstrument == null && _catalog.length > 1) {
      _toCode = _catalog[1].code;
    }

    if (canConvert) {
      _executeConversion();
    } else {
      notifyListeners();
    }
  }

  void updateAmount(String value) {
    _rawAmount = value;
    _validation = InputValidator.validateAmount(value);
    _errorMessage = _validation.isValid ? null : _validation.errorMessage;
    if (!_validation.isValid) {
      _result = null;
    }
    notifyListeners();
  }

  void selectFrom(String code) {
    _fromCode = code;
    if (canConvert) {
      _executeConversion();
    } else {
      notifyListeners();
    }
  }

  void selectTo(String code) {
    _toCode = code;
    if (canConvert) {
      _executeConversion();
    } else {
      notifyListeners();
    }
  }

  void swap() {
    final prevFrom = _fromCode;
    _fromCode = _toCode;
    _toCode = prevFrom;
    if (canConvert) {
      _executeConversion();
    } else {
      notifyListeners();
    }
  }

  void convert() {
    _validation = InputValidator.validateAmount(_rawAmount);
    if (!_validation.isValid) {
      _errorMessage = _validation.errorMessage;
      _result = null;
      notifyListeners();
      return;
    }
    _executeConversion();
  }

  void _executeConversion() {
    final from = fromInstrument;
    final to = toInstrument;
    if (from == null || to == null) return;

    try {
      _result = _convertAssets(
        rawAmount: _rawAmount,
        from: from,
        to: to,
        isOffline: _isOffline,
      );
      _errorMessage = null;
    } on AppFailure catch (e) {
      _errorMessage = e.message;
      _result = null;
    }
    notifyListeners();
  }

  ConvertibleInstrument? _findByCode(String code) {
    for (final item in _catalog) {
      if (item.code == code) return item;
    }
    return null;
  }
}
