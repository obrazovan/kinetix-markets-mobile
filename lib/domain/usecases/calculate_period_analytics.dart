import '../entities/candle_point.dart';
import '../entities/period_analytics.dart';

/// Pure deterministic calculator for 7-day and 30-day comparison analytics.
class CalculatePeriodAnalytics {
  const CalculatePeriodAnalytics();

  static const double _flatThresholdPercent = 0.005;

  /// Computes statistics for [timeframe] from chronological [candles].
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
      final takeCount = sorted.length < timeframe.days ? sorted.length : timeframe.days;
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
    );
  }
}
