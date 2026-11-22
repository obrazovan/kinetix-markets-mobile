import 'dart:convert';

import '../../core/errors/failures.dart';
import '../../domain/entities/candle_point.dart';

/// Parses Binance REST klines and 24hr ticker payloads.
class BinanceParser {
  const BinanceParser();

  /// Parses `/api/v3/klines` array into chronological [CandlePoint]s.
  List<CandlePoint> parseKlines(String rawJson) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(rawJson);
    } catch (e) {
      throw ParseFailure('Неверный формат JSON от Binance Klines', e.toString());
    }

    if (decoded is! List) {
      throw const ParseFailure('Ожидался массив свечей от Binance');
    }

    final points = <CandlePoint>[];
    for (final row in decoded) {
      if (row is! List || row.length < 6) continue;
      final openMs = _toInt(row[0]);
      final open = _toDouble(row[1]);
      final high = _toDouble(row[2]);
      final low = _toDouble(row[3]);
      final close = _toDouble(row[4]);
      final volume = _toDouble(row[5]) ?? 0.0;

      if (openMs == null ||
          open == null ||
          high == null ||
          low == null ||
          close == null ||
          close <= 0) {
        continue;
      }

      points.add(
        CandlePoint(
          timestamp: DateTime.fromMillisecondsSinceEpoch(openMs, isUtc: true),
          open: open,
          high: high,
          low: low,
          close: close,
          volume: volume,
        ),
      );
    }

    points.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return points;
  }

  /// Parses `/api/v3/ticker/24hr` into map `symbol -> (lastPrice, changePct)`.
  Map<String, ({double price, double changePercent})> parseTickers24h(
    String rawJson,
  ) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(rawJson);
    } catch (e) {
      throw ParseFailure('Неверный JSON тикеров Binance', e.toString());
    }

    if (decoded is! List) {
      throw const ParseFailure('Ожидался список тикеров Binance');
    }

    final result = <String, ({double price, double changePercent})>{};
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      final symbol = item['symbol'] as String?;
      final price = _toDouble(item['lastPrice']);
      final pct = _toDouble(item['priceChangePercent']) ?? 0.0;
      if (symbol != null && price != null && price > 0) {
        result[symbol] = (price: price, changePercent: pct);
      }
    }
    return result;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) {
      final d = value.toDouble();
      return (d.isNaN || d.isInfinite) ? null : d;
    }
    if (value is String) {
      final d = double.tryParse(value);
      return (d == null || d.isNaN || d.isInfinite) ? null : d;
    }
    return null;
  }
}
