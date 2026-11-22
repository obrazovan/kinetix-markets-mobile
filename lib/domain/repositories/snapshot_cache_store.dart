import '../entities/market_snapshot.dart';

/// Persistence contract for offline market snapshots surviving restarts.
abstract interface class SnapshotCacheStore {
  Future<void> saveSnapshot(MarketSnapshot snapshot);
  Future<MarketSnapshot?> loadSnapshot();
  Future<void> clear();
}
