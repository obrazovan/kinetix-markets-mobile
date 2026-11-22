import 'package:flutter_test/flutter_test.dart';
import 'package:kinetix_markets/core/errors/failures.dart';
import 'package:kinetix_markets/domain/entities/convertible_instrument.dart';
import 'package:kinetix_markets/domain/entities/market_asset.dart';
import 'package:kinetix_markets/domain/entities/market_snapshot.dart';
import 'package:kinetix_markets/domain/usecases/convert_assets.dart';

void main() {
  group('ConvertAssets', () {
    const useCase = ConvertAssets();
    final now = DateTime.utc(2026, 11, 22, 12, 0);

    final snapshot = MarketSnapshot(
      fetchedAt: now,
      isOffline: false,
      assets: [
        MarketAsset(
          symbol: 'USD/MDL',
          displayPair: 'USD/MDL',
          name: 'US Dollar / Moldovan Leu',
          category: AssetCategory.forex,
          quoteCurrency: 'MDL',
          currentPrice: 18.0,
          usdEquivalentPrice: 1.0,
          change24hPercent: 0.1,
          source: 'BNM XML',
          updatedAt: now,
          candles: const [],
        ),
        MarketAsset(
          symbol: 'BTC',
          displayPair: 'BTC/USDT',
          name: 'Bitcoin',
          category: AssetCategory.crypto,
          quoteCurrency: 'USDT',
          currentPrice: 90000.0,
          usdEquivalentPrice: 90000.0,
          change24hPercent: 2.5,
          source: 'Binance',
          updatedAt: now,
          candles: const [],
        ),
      ],
    );

    final catalog = ConvertibleInstrument.catalogFromSnapshot(snapshot);
    ConvertibleInstrument byCode(String code) =>
        catalog.firstWhere((e) => e.code == code);

    test('converts cross-assets accurately (USD -> MDL and BTC -> MDL)', () {
      final usdToMdl = useCase(
        rawAmount: '100',
        from: byCode('USD'),
        to: byCode('MDL'),
        isOffline: false,
      );
      expect(usdToMdl.convertedAmount, closeTo(1800.0, 1e-6));
      expect(usdToMdl.directRate, closeTo(18.0, 1e-6));
      expect(usdToMdl.isSameAsset, isFalse);

      final btcToMdl = useCase(
        rawAmount: '0,5',
        from: byCode('BTC'),
        to: byCode('MDL'),
        isOffline: true,
      );
      expect(btcToMdl.convertedAmount, closeTo(810000.0, 1e-4));
      expect(btcToMdl.isOffline, isTrue);
    });

    test('returns deterministic 1.0 rate for identical asset conversion', () {
      final same = useCase(
        rawAmount: '250.75',
        from: byCode('USD'),
        to: byCode('USD'),
        isOffline: false,
      );
      expect(same.isSameAsset, isTrue);
      expect(same.directRate, 1.0);
      expect(same.inverseRate, 1.0);
      expect(same.convertedAmount, 250.75);
    });

    test('throws ValidationFailure for invalid amount', () {
      expect(
        () => useCase(
          rawAmount: '-10',
          from: byCode('USD'),
          to: byCode('MDL'),
          isOffline: false,
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });
}
