import '../entities/market_snapshot.dart';

/// Abstraction for retrieving unified market snapshots with offline resilience.
abstract interface class MarketRepository {
  Future<MarketSnapshot> loadSnapshot({bool forceRefresh = false});
  Future<MarketSnapshot?> loadCachedOnly();
}
