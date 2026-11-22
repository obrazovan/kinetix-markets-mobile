import 'candle_point.dart';

/// Mandatory comparison windows required by specification.
enum AnalyticsTimeframe {
  week7d(days: 7, titleRu: 'Неделя (7Д)', shortLabel: '7D'),
  month30d(days: 30, titleRu: 'Месяц (30Д)', shortLabel: '30D');

  const AnalyticsTimeframe({
    required this.days,
    required this.titleRu,
    required this.shortLabel,
  });

  final int days;
  final String titleRu;
  final String shortLabel;
}

/// Explicit directional trend for comparison screens.
enum TrendDirection {
  up('Рост'),
  down('Падение'),
  flat('Без изменений');

  const TrendDirection(this.labelRu);

  final String labelRu;
}

/// Computed statistical summary for a 7-day or 30-day window.
class PeriodAnalytics {
  const PeriodAnalytics({
    required this.timeframe,
    required this.assetSymbol,
    required this.points,
    required this.startPrice,
    required this.endPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.averagePrice,
    required this.absoluteChange,
    required this.percentChange,
    required this.volatilityPercent,
    required this.trend,
    required this.isEmpty,
  });

  factory PeriodAnalytics.empty({
    required AnalyticsTimeframe timeframe,
    required String assetSymbol,
  }) {
    return PeriodAnalytics(
      timeframe: timeframe,
      assetSymbol: assetSymbol,
      points: const [],
      startPrice: 0,
      endPrice: 0,
      minPrice: 0,
      maxPrice: 0,
      averagePrice: 0,
      absoluteChange: 0,
      percentChange: 0,
      volatilityPercent: 0,
      trend: TrendDirection.flat,
      isEmpty: true,
    );
  }

  final AnalyticsTimeframe timeframe;
  final String assetSymbol;
  final List<CandlePoint> points;
  final double startPrice;
  final double endPrice;
  final double minPrice;
  final double maxPrice;
  final double averagePrice;
  final double absoluteChange;
  final double percentChange;
  final double volatilityPercent;
  final TrendDirection trend;
  final bool isEmpty;
}
