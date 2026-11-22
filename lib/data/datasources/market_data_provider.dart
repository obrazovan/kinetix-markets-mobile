import '../../domain/entities/market_asset.dart';

/// Contract implemented by all market data sources (SOLID OCP / LSP / DIP).
abstract interface class MarketDataProvider {
  String get providerName;
  AssetCategory get category;
  Future<List<MarketAsset>> fetchAssetsWithHistory({int days = 30});
}
