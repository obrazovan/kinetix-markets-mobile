import 'package:flutter_test/flutter_test.dart';
import 'package:kinetix_markets/domain/entities/candle_point.dart';
import 'package:kinetix_markets/domain/entities/period_analytics.dart';
import 'package:kinetix_markets/domain/usecases/calculate_period_analytics.dart';

void main() {
  const calculator = CalculatePeriodAnalytics();

  List<CandlePoint> makeSeries(List<double> closes, {int startDay = 1}) {
    final base = DateTime.utc(2026, 11, startDay);
    return List.generate(closes.length, (i) {
      final p = closes[i];
      return CandlePoint(
        timestamp: base.add(Duration(days: i)),
        open: p,
        high: p * 1.01,
        low: p * 0.99,
        close: p,
      );
    });
  }

  group('CalculatePeriodAnalytics', () {
    test('computes 7D min, max, average, absolute, percent, and upward trend', () {
      final candles = makeSeries([100, 105, 95, 110, 115, 105, 120]);
      final result = calculator(
        assetSymbol: 'AAPL',
        candles: candles,
        timeframe: AnalyticsTimeframe.week7d,
      );

      expect(result.isEmpty, isFalse);
      expect(result.points, hasLength(7));
      expect(result.minPrice, 95.0);
      expect(result.maxPrice, 120.0);
      expect(result.averagePrice, closeTo(750 / 7, 1e-6));
      expect(result.absoluteChange, 20.0);
      expect(result.percentChange, closeTo(20.0, 1e-6));
      expect(result.trend, TrendDirection.up);
      expect(result.smaSeries, hasLength(7));
      expect(result.rsi14, isNotNull);
    });

    test('slices last 30 days accurately and detects downward trend', () {
      // 35 days: first 5 days high (200), next 30 days declining from 150 down to 120.
      final closes = <double>[
        200, 200, 200, 200, 200,
        for (var i = 0; i < 30; i++) 150.0 - i,
      ];
      final candles = makeSeries(closes);
      final result = calculator(
        assetSymbol: 'BTC',
        candles: candles,
        timeframe: AnalyticsTimeframe.month30d,
      );

      expect(result.points, hasLength(30));
      expect(result.startPrice, 150.0);
      expect(result.endPrice, 121.0);
      expect(result.minPrice, 121.0);
      expect(result.maxPrice, 150.0);
      expect(result.absoluteChange, closeTo(-29.0, 1e-6));
      expect(result.percentChange, closeTo((-29.0 / 150.0) * 100.0, 1e-6));
      expect(result.trend, TrendDirection.down);
    });

    test('detects flat trend when start and end prices are equal', () {
      final candles = makeSeries([18.0, 18.2, 17.9, 18.0, 18.0, 18.1, 18.0]);
      final result = calculator(
        assetSymbol: 'USD/MDL',
        candles: candles,
        timeframe: AnalyticsTimeframe.week7d,
      );

      expect(result.absoluteChange, 0.0);
      expect(result.percentChange, 0.0);
      expect(result.trend, TrendDirection.flat);
    });

    test('handles empty dataset safely without exceptions', () {
      final result = calculator(
        assetSymbol: 'EMPTY',
        candles: const [],
        timeframe: AnalyticsTimeframe.month30d,
      );

      expect(result.isEmpty, isTrue);
      expect(result.points, isEmpty);
      expect(result.minPrice, 0.0);
      expect(result.maxPrice, 0.0);
      expect(result.averagePrice, 0.0);
      expect(result.percentChange, 0.0);
      expect(result.trend, TrendDirection.flat);
    });
  });
}
