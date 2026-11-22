import 'dart:convert';

import '../../core/errors/failures.dart';
import '../../domain/entities/candle_point.dart';

/// Parsed output from Yahoo Finance v8 chart response.
class YahooChartParsed {
  const YahooChartParsed({
    required this.currentPrice,
    required this.changePercent,
    required this.candles,
  });

  final double currentPrice;
  final double changePercent;
  final List<CandlePoint> candles;
}

/// Parses Yahoo Finance `/v8/finance/chart/{symbol}` JSON payloads.
class YahooParser {
  const YahooParser();

  YahooChartParsed parseChart(String rawJson) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(rawJson);
    } catch (e) {
      throw ParseFailure('Неверный формат JSON от Yahoo Finance', e.toString());
    }

    if (decoded is! Map<String, dynamic>) {
      throw const ParseFailure('Ожидался JSON-объект от Yahoo Finance');
    }

    final chart = decoded['chart'];
    if (chart is! Map<String, dynamic>) {
      throw const ParseFailure('Отсутствует секция chart в ответе Yahoo');
    }

    final results = chart['result'];
    if (results is! List || results.isEmpty || results.first is! Map<String, dynamic>) {
      throw const ParseFailure('Пустой список котировок Yahoo Finance');
    }

    final entry = results.first as Map<String, dynamic>;
    final meta = entry['meta'] as Map<String, dynamic>? ?? const {};
    final timestamps = entry['timestamp'] as List<dynamic>? ?? const [];
    final indicators = entry['indicators'] as Map<String, dynamic>? ?? const {};
    final quotesList = indicators['quote'] as List<dynamic>? ?? const [];
    final quote = quotesList.isNotEmpty && quotesList.first is Map<String, dynamic>
        ? quotesList.first as Map<String, dynamic>
        : const <String, dynamic>{};

    final opens = quote['open'] as List<dynamic>? ?? const [];
    final highs = quote['high'] as List<dynamic>? ?? const [];
    final lows = quote['low'] as List<dynamic>? ?? const [];
    final closes = quote['close'] as List<dynamic>? ?? const [];
    final volumes = quote['volume'] as List<dynamic>? ?? const [];

    final candles = <CandlePoint>[];
    for (var i = 0; i < timestamps.length; i++) {
      final ts = _asInt(timestamps[i]);
      final close = i < closes.length ? _asDouble(closes[i]) : null;
      if (ts == null || close == null || close <= 0) continue;

      final open = (i < opens.length ? _asDouble(opens[i]) : null) ?? close;
      final high = (i < highs.length ? _asDouble(highs[i]) : null) ?? close;
      final low = (i < lows.length ? _asDouble(lows[i]) : null) ?? close;
      final vol = (i < volumes.length ? _asDouble(volumes[i]) : null) ?? 0.0;

      candles.add(
        CandlePoint(
          timestamp: DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true),
          open: open,
          high: high < close ? close : high,
          low: low > close ? close : low,
          close: close,
          volume: vol,
        ),
      );
    }

    candles.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final metaPrice = _asDouble(meta['regularMarketPrice']);
    final currentPrice = metaPrice ?? (candles.isNotEmpty ? candles.last.close : 0.0);
    if (currentPrice <= 0) {
      throw const ParseFailure('Не удалось определить текущую цену акции');
    }

    var changePct = 0.0;
    if (candles.length >= 2) {
      final prevClose = candles[candles.length - 2].close;
      if (prevClose > 0) {
        changePct = ((currentPrice - prevClose) / prevClose) * 100.0;
      }
    } else {
      final prev = _asDouble(meta['chartPreviousClose']);
      if (prev != null && prev > 0) {
        changePct = ((currentPrice - prev) / prev) * 100.0;
      }
    }

    return YahooChartParsed(
      currentPrice: currentPrice,
      changePercent: changePct,
      candles: candles,
    );
  }

  static int? _asInt(dynamic v) => v is num ? v.toInt() : null;

  static double? _asDouble(dynamic v) {
    if (v is num) {
      final d = v.toDouble();
      return (d.isNaN || d.isInfinite) ? null : d;
    }
    return null;
  }
}
