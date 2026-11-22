import '../../core/errors/failures.dart';
import '../../domain/entities/market_asset.dart';
import '../../domain/entities/market_snapshot.dart';
import '../../domain/repositories/market_repository.dart';
import '../../domain/repositories/snapshot_cache_store.dart';
import '../datasources/market_data_provider.dart';

/// Aggregates market providers with partial-failure resilience & offline cache.
class MarketRepositoryImpl implements MarketRepository {
  MarketRepositoryImpl({
    required List<MarketDataProvider> providers,
    required SnapshotCacheStore cacheStore,
  })  : _providers = providers,
        _cacheStore = cacheStore;

  final List<MarketDataProvider> _providers;
  final SnapshotCacheStore _cacheStore;

  @override
  Future<MarketSnapshot?> loadCachedOnly() async {
    final cached = await _cacheStore.loadSnapshot();
    return cached?.copyWith(isOffline: true);
  }

  @override
  Future<MarketSnapshot> loadSnapshot({bool forceRefresh = false}) async {
    final warnings = <String>[];
    final freshAssets = <MarketAsset>[];

    final settled = await Future.wait(
      _providers.map((provider) async {
        try {
          final items = await provider.fetchAssetsWithHistory(days: 30);
          return (provider: provider.providerName, items: items, error: null);
        } catch (e) {
          return (
            provider: provider.providerName,
            items: const <MarketAsset>[],
            error: e.toString(),
          );
        }
      }),
    );

    for (final result in settled) {
      if (result.items.isNotEmpty) {
        freshAssets.addAll(result.items);
      } else if (result.error != null) {
        warnings.add('${result.provider}: источник временно недоступен');
      }
    }

    if (freshAssets.isNotEmpty) {
      // If one provider failed partially, preserve cached assets for missing symbols.
      final cached = await _cacheStore.loadSnapshot();
      final merged = _mergeWithFallback(freshAssets, cached?.assets ?? const []);
      final snapshot = MarketSnapshot(
        assets: merged,
        fetchedAt: DateTime.now(),
        isOffline: false,
        warnings: warnings,
      );
      await _cacheStore.saveSnapshot(snapshot);
      return snapshot;
    }

    // Complete network outage: serve persisted offline cache cleanly.
    final cached = await _cacheStore.loadSnapshot();
    if (cached != null && cached.assets.isNotEmpty) {
      return cached.copyWith(
        isOffline: true,
        warnings: [
          'Нет подключения к сети. Показаны сохранённые котировки.',
        ],
      );
    }

    throw const NetworkFailure(
      'Нет соединения с интернетом и отсутствует локальный кэш. '
      'Подключитесь к сети для первичной загрузки котировок.',
    );
  }

  List<MarketAsset> _mergeWithFallback(
    List<MarketAsset> fresh,
    List<MarketAsset> cached,
  ) {
    final seen = fresh.map((a) => a.symbol).toSet();
    final combined = <MarketAsset>[...fresh];
    for (final oldAsset in cached) {
      if (!seen.contains(oldAsset.symbol)) {
        combined.add(oldAsset);
      }
    }
    return combined;
  }
}
