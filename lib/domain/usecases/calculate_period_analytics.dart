import '../entities/candle_point.dart';
import '../entities/period_analytics.dart';

/// Pure deterministic calculator for 7D/14D/30D analytics, SMA, and RSI(14).
class CalculatePeriodAnalytics {
  const CalculatePeriodAnalytics();

  static const double _flatThresholdPercent = 0.005;

  /// Computes statistics, moving average, and RSI for [timeframe].
  PeriodAnalytics call({
    required String assetSymbol,
    required List<CandlePoint> candles,
    required AnalyticsTimeframe timeframe,
  }) {
    if (candles.isEmpty) {
      return PeriodAnalytics.empty(
        timeframe: timeframe,
        assetSymbol: assetSymbol,
      );
    }

    final sorted = List<CandlePoint>.from(candles)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final latest = sorted.last.timestamp;
    final cutoff = DateTime(
      latest.year,
      latest.month,
      latest.day,
    ).subtract(Duration(days: timeframe.days - 1));

    var windowPoints = sorted
        .where((c) => !c.timestamp.isBefore(cutoff))
        .toList(growable: false);

    if (windowPoints.isEmpty) {
      final takeCount =
          sorted.length < timeframe.days ? sorted.length : timeframe.days;
      windowPoints = sorted.sublist(sorted.length - takeCount);
    }

    final startPrice = windowPoints.first.close;
    final endPrice = windowPoints.last.close;

    var minPrice = windowPoints.first.close;
    var maxPrice = windowPoints.first.close;
    var sum = 0.0;

    for (final point in windowPoints) {
      if (point.close < minPrice) minPrice = point.close;
      if (point.close > maxPrice) maxPrice = point.close;
      sum += point.close;
    }

    final averagePrice = sum / windowPoints.length;
    final absoluteChange = endPrice - startPrice;
    final percentChange =
        startPrice == 0 ? 0.0 : (absoluteChange / startPrice) * 100.0;
    final volatilityPercent =
        averagePrice == 0 ? 0.0 : ((maxPrice - minPrice) / averagePrice) * 100.0;

    final TrendDirection trend;
    if (absoluteChange.abs() <= 1e-9 ||
        percentChange.abs() < _flatThresholdPercent) {
      trend = TrendDirection.flat;
    } else if (absoluteChange > 0) {
      trend = TrendDirection.up;
    } else {
      trend = TrendDirection.down;
    }

    final smaSeries = _computeSma(windowPoints, period: 5);
    final rsi14 = _computeRsi(sorted, period: 14);

    return PeriodAnalytics(
      timeframe: timeframe,
      assetSymbol: assetSymbol,
      points: windowPoints,
      startPrice: startPrice,
      endPrice: endPrice,
      minPrice: minPrice,
      maxPrice: maxPrice,
      averagePrice: averagePrice,
      absoluteChange: absoluteChange,
      percentChange: percentChange,
      volatilityPercent: volatilityPercent,
      trend: trend,
      isEmpty: false,
      smaSeries: smaSeries,
      rsi14: rsi14,
    );
  }

  static List<double?> _computeSma(
    List<CandlePoint> points, {
    required int period,
  }) {
    if (points.length < 2) return const [];
    final effectivePeriod = points.length < period ? points.length : period;
    final result = <double?>[];
    for (var i = 0; i < points.length; i++) {
      if (i + 1 < effectivePeriod) {
        // Warm-up average over available prefix so curve is continuous.
        var s = 0.0;
        for (var j = 0; j <= i; j++) {
          s += points[j].close;
        }
        result.add(s / (i + 1));
      } else {
        var s = 0.0;
        for (var j = i - effectivePeriod + 1; j <= i; j++) {
          s += points[j].close;
        }
        result.add(s / effectivePeriod);
      }
    }
    return result;
  }

  static double? _computeRsi(
    List<CandlePoint> sorted, {
    required int period,
  }) {
    if (sorted.length < 3) return null;
    final lookback = sorted.length - 1 < period ? sorted.length - 1 : period;
    final startIdx = sorted.length - lookback;
    var gains = 0.0;
    var losses = 0.0;

    for (var i = startIdx; i < sorted.length; i++) {
      final diff = sorted[i].close - sorted[i - 1].close;
      if (diff > 0) {
        gains += diff;
      } else if (diff < 0) {
        losses += diff.abs();
      }
    }

    final avgGain = gains / lookback;
    final avgLoss = losses / lookback;
    if (avgGain == 0 && avgLoss == 0) return 50.0;
    if (avgLoss == 0) return 100.0;
    final rs = avgGain / avgLoss;
    return 100.0 - (100.0 / (1.0 + rs));
  }
}
