import 'package:flutter_test/flutter_test.dart';
import 'package:kinetix_markets/core/errors/failures.dart';
import 'package:kinetix_markets/data/cache/local_snapshot_cache_store.dart';
import 'package:kinetix_markets/data/datasources/market_data_provider.dart';
import 'package:kinetix_markets/data/repositories/market_repository_impl.dart';
import 'package:kinetix_markets/domain/entities/candle_point.dart';
import 'package:kinetix_markets/domain/entities/market_asset.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeProvider implements MarketDataProvider {
  _FakeProvider({
    required this.providerName,
    required this.category,
    this.assets = const [],
    this.shouldThrow = false,
  });

  @override
  final String providerName;

  @override
  final AssetCategory category;

  final List<MarketAsset> assets;
  final bool shouldThrow;

  @override
  Future<List<MarketAsset>> fetchAssetsWithHistory({int days = 30}) async {
    if (shouldThrow) {
      throw const NetworkFailure('Simulated offline failure');
    }
    return assets;
  }
}

void main() {
  final sampleAsset = MarketAsset(
    symbol: 'AAPL',
    displayPair: 'AAPL',
    name: 'Apple Inc.',
    category: AssetCategory.stock,
    quoteCurrency: 'USD',
    currentPrice: 228.5,
    usdEquivalentPrice: 228.5,
    change24hPercent: 1.25,
    source: 'Yahoo Finance',
    updatedAt: DateTime.utc(2026, 11, 22, 10, 0),
    candles: [
      CandlePoint(
        timestamp: DateTime.utc(2026, 11, 21),
        open: 225.0,
        high: 229.0,
        low: 224.5,
        close: 228.5,
      ),
    ],
  );

  group('Offline Persistence & MarketRepositoryImpl', () {
    test('persists snapshot across simulated app restart and serves offline', () async {
      SharedPreferences.setMockInitialValues({});
      final store1 = LocalSnapshotCacheStore();
      final onlineRepo = MarketRepositoryImpl(
        providers: [
          _FakeProvider(
            providerName: 'Yahoo',
            category: AssetCategory.stock,
            assets: [sampleAsset],
          ),
        ],
        cacheStore: store1,
      );

      final live = await onlineRepo.loadSnapshot();
      expect(live.isOffline, isFalse);
      expect(live.assets, hasLength(1));

      // Simulate cold restart with fresh cache store & failing network providers.
      final store2 = LocalSnapshotCacheStore();
      final offlineRepo = MarketRepositoryImpl(
        providers: [
          _FakeProvider(
            providerName: 'Yahoo',
            category: AssetCategory.stock,
            shouldThrow: true,
          ),
        ],
        cacheStore: store2,
      );

      final recovered = await offlineRepo.loadSnapshot();
      expect(recovered.isOffline, isTrue);
      expect(recovered.assets.first.symbol, 'AAPL');
      expect(recovered.warnings, isNotEmpty);
    });

    test('handles corrupted cache safely and throws NetworkFailure when empty', () async {
      SharedPreferences.setMockInitialValues({
        LocalSnapshotCacheStore.cacheKey: '{corrupted-json',
      });
      final store = LocalSnapshotCacheStore();
      expect(await store.loadSnapshot(), isNull);

      final repo = MarketRepositoryImpl(
        providers: [
          _FakeProvider(
            providerName: 'Binance',
            category: AssetCategory.crypto,
            shouldThrow: true,
          ),
        ],
        cacheStore: store,
      );

      expect(repo.loadSnapshot(), throwsA(isA<NetworkFailure>()));
    });
  });
}
