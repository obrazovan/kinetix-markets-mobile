import 'package:flutter_test/flutter_test.dart';
import 'package:kinetix_markets/app/app.dart';
import 'package:kinetix_markets/domain/entities/candle_point.dart';
import 'package:kinetix_markets/domain/entities/market_asset.dart';
import 'package:kinetix_markets/domain/entities/market_snapshot.dart';
import 'package:kinetix_markets/domain/repositories/market_repository.dart';
import 'package:kinetix_markets/domain/usecases/calculate_period_analytics.dart';
import 'package:kinetix_markets/domain/usecases/convert_assets.dart';
import 'package:kinetix_markets/domain/usecases/load_market_snapshot.dart';
import 'package:kinetix_markets/presentation/controllers/converter_controller.dart';
import 'package:kinetix_markets/presentation/controllers/market_terminal_controller.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubMarketRepository implements MarketRepository {
  _StubMarketRepository({required this.snapshot});

  final MarketSnapshot snapshot;

  @override
  Future<MarketSnapshot?> loadCachedOnly() async => null;

  @override
  Future<MarketSnapshot> loadSnapshot({bool forceRefresh = false}) async {
    return snapshot;
  }
}

MarketSnapshot _buildSampleSnapshot({required bool isOffline}) {
  final base = DateTime.utc(2026, 10, 24);
  final btcCandles = List.generate(30, (i) {
    final p = 80000.0 + (i * 500.0);
    return CandlePoint(
      timestamp: base.add(Duration(days: i)),
      open: p - 200,
      high: p + 350,
      low: p - 300,
      close: p,
    );
  });

  final mdlCandles = List.generate(30, (i) {
    const p = 18.0;
    return CandlePoint(
      timestamp: base.add(Duration(days: i)),
      open: p,
      high: p,
      low: p,
      close: p,
    );
  });

  final updated = DateTime.utc(2026, 11, 22, 12, 30);
  return MarketSnapshot(
    fetchedAt: updated,
    isOffline: isOffline,
    assets: [
      MarketAsset(
        symbol: 'BTC',
        displayPair: 'BTC/USDT',
        name: 'Bitcoin',
        category: AssetCategory.crypto,
        quoteCurrency: 'USDT',
        currentPrice: 94500.0,
        usdEquivalentPrice: 94500.0,
        change24hPercent: 4.2,
        source: 'Binance',
        updatedAt: updated,
        candles: btcCandles,
      ),
      MarketAsset(
        symbol: 'USD/MDL',
        displayPair: 'USD/MDL',
        name: 'US Dollar / Moldovan Leu',
        category: AssetCategory.forex,
        quoteCurrency: 'MDL',
        currentPrice: 18.0,
        usdEquivalentPrice: 1.0,
        change24hPercent: 0.0,
        source: 'BNM XML',
        updatedAt: updated,
        candles: mdlCandles,
      ),
    ],
  );
}

Widget _buildTestApp({required bool isOffline}) {
  final repo = _StubMarketRepository(
    snapshot: _buildSampleSnapshot(isOffline: isOffline),
  );
  final terminal = MarketTerminalController(
    loadMarketSnapshot: LoadMarketSnapshot(repo),
    calculatePeriodAnalytics: const CalculatePeriodAnalytics(),
    repository: repo,
  );
  final converter = ConverterController(convertAssets: const ConvertAssets());
  terminal.initialize();

  return KinetixMarketsApp(
    terminalController: terminal,
    converterController: converter,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'renders Markets, unified Analytics (7D & 30D timeframes), and Portfolio screens',
    (tester) async {
      await tester.pumpWidget(_buildTestApp(isOffline: false));
      await tester.pumpAndSettle();

      // Markets screen shows BTC/USDT and USD/MDL.
      expect(find.text('BTC/USDT'), findsWidgets);
      expect(find.text('USD/MDL'), findsWidgets);

      // Navigate to unified Analytics tab (defaults to 7D).
      await tester.tap(find.text('Аналитика'));
      await tester.pumpAndSettle();

      expect(find.text('Аналитика и сравнение'), findsOneWidget);
      expect(find.textContaining('Период: Неделя (7Д)'), findsOneWidget);
      expect(find.text('Рост'), findsWidgets);

      // Scroll to inspect mandatory 7D metrics.
      await tester.drag(
        find.text('Аналитика и сравнение'),
        const Offset(0, -350),
      );
      await tester.pumpAndSettle();
      expect(find.text('Минимум за период'), findsOneWidget);
      expect(find.text('Максимум за период'), findsOneWidget);
      expect(find.text('Среднее значение'), findsOneWidget);
      expect(find.text('Изменение (абс. / %)'), findsOneWidget);
      expect(find.text('Направление тенденции'), findsOneWidget);

      // Scroll back up and switch timeframe to Monthly (30D).
      await tester.drag(
        find.text('Минимум за период'),
        const Offset(0, 350),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('timeframe_month30d')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Период: Месяц (30Д)'), findsOneWidget);
      await tester.drag(
        find.text('Аналитика и сравнение'),
        const Offset(0, -550),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.text('Среднее значение'),
        const Offset(0, -450),
      );
      await tester.pumpAndSettle();
      expect(find.text('Контекст: 7Д vs 30Д'), findsOneWidget);
      await tester.drag(
        find.text('Контекст: 7Д vs 30Д'),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Сравнение доходности за 30Д'), findsOneWidget);

      // Navigate to Portfolio tab.
      await tester.tap(find.text('Портфель'));
      await tester.pumpAndSettle();
      expect(find.text('Инвестиционный портфель'), findsOneWidget);
      expect(find.text('Оценка активов'), findsOneWidget);
    },
  );

  testWidgets(
    'converter enforces disabled submit guard and offline banner displays cached timestamp',
    (tester) async {
      await tester.pumpWidget(_buildTestApp(isOffline: true));
      await tester.pumpAndSettle();

      // Offline banner explicitly displays cached snapshot timestamp.
      expect(
        find.textContaining('Офлайн-режим • Данные из кэша от'),
        findsOneWidget,
      );

      // Switch to Converter tab.
      await tester.tap(find.text('Конвертер'));
      await tester.pumpAndSettle();

      // Invalid input '0' disables the Convert button.
      await tester.enterText(
        find.byKey(const ValueKey('converter_amount_field')),
        '0',
      );
      await tester.pumpAndSettle();

      final disabledBtn = tester.widget<FilledButton>(
        find.byKey(const ValueKey('converter_submit_button')),
      );
      expect(disabledBtn.onPressed, isNull);
      expect(
        find.text('Сумма должна быть строго больше нуля'),
        findsOneWidget,
      );

      // Valid comma-decimal input '100,5' enables the button and converts.
      await tester.enterText(
        find.byKey(const ValueKey('converter_amount_field')),
        '100,5',
      );
      await tester.pumpAndSettle();

      final enabledBtn = tester.widget<FilledButton>(
        find.byKey(const ValueKey('converter_submit_button')),
      );
      expect(enabledBtn.onPressed, isNotNull);
      await tester.tap(find.byKey(const ValueKey('converter_submit_button')));
      await tester.pumpAndSettle();

      await tester.drag(
        find.text('Мультивалютный конвертер'),
        const Offset(0, -250),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('1 809.00 MDL'), findsOneWidget);
    },
  );
}
