import 'dart:convert';

import '../../core/errors/failures.dart';
import '../../domain/entities/candle_point.dart';

/// Parses Frankfurter ECB time-series responses (`/{start}..{end}?from=USD`).
class FrankfurterParser {
  const FrankfurterParser();

  /// Returns chronological map `currencyCode -> List<CandlePoint>` (USD-based rate).
  Map<String, List<CandlePoint>> parseTimeSeries(
    String rawJson, {
    required Set<String> invertPairs,
  }) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(rawJson);
    } catch (e) {
      throw ParseFailure('Неверный формат JSON от Frankfurter', e.toString());
    }

    if (decoded is! Map<String, dynamic>) {
      throw const ParseFailure('Ожидался объект истории от Frankfurter');
    }

    final ratesMap = decoded['rates'];
    if (ratesMap is! Map<String, dynamic> || ratesMap.isEmpty) {
      throw const ParseFailure('Пустой набор исторических курсов Frankfurter');
    }

    final sortedDates = ratesMap.keys.toList()..sort();
    final series = <String, List<CandlePoint>>{};

    for (final dateStr in sortedDates) {
      final timestamp = DateTime.tryParse(dateStr);
      final dayRates = ratesMap[dateStr];
      if (timestamp == null || dayRates is! Map<String, dynamic>) continue;

      for (final entry in dayRates.entries) {
        final code = entry.key;
        final rawRate = entry.value is num ? (entry.value as num).toDouble() : null;
        if (rawRate == null || rawRate <= 0 || rawRate.isNaN || rawRate.isInfinite) {
          continue;
        }

        final normalizedRate = invertPairs.contains(code) ? (1.0 / rawRate) : rawRate;
        series.putIfAbsent(code, () => []).add(
              CandlePoint(
                timestamp: DateTime.utc(
                  timestamp.year,
                  timestamp.month,
                  timestamp.day,
                ),
                open: normalizedRate,
                high: normalizedRate,
                low: normalizedRate,
                close: normalizedRate,
              ),
            );
      }
    }

    return series;
  }
}
