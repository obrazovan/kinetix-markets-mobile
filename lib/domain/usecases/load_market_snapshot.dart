import '../entities/market_snapshot.dart';
import '../repositories/market_repository.dart';

/// Loads live or offline-cached market data via [MarketRepository].
class LoadMarketSnapshot {
  const LoadMarketSnapshot(this._repository);

  final MarketRepository _repository;

  Future<MarketSnapshot> call({bool forceRefresh = false}) {
    return _repository.loadSnapshot(forceRefresh: forceRefresh);
  }
}
