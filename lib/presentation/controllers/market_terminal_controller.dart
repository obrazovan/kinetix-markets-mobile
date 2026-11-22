import 'package:flutter/foundation.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/market_asset.dart';
import '../../domain/entities/market_snapshot.dart';
import '../../domain/entities/period_analytics.dart';
import '../../domain/repositories/market_repository.dart';
import '../../domain/usecases/calculate_period_analytics.dart';
import '../../domain/usecases/load_market_snapshot.dart';

/// State controller for Markets Terminal, Asset Details, and 7D/30D Analytics.
class MarketTerminalController extends ChangeNotifier {
  MarketTerminalController({
    required LoadMarketSnapshot loadMarketSnapshot,
    required CalculatePeriodAnalytics calculatePeriodAnalytics,
    required MarketRepository repository,
  })  : _loadMarketSnapshot = loadMarketSnapshot,
        _calculatePeriodAnalytics = calculatePeriodAnalytics,
        _repository = repository;

  final LoadMarketSnapshot _loadMarketSnapshot;
  final CalculatePeriodAnalytics _calculatePeriodAnalytics;
  final MarketRepository _repository;

  MarketSnapshot? _snapshot;
  bool _isLoading = false;
  String? _errorMessage;
  AssetCategory? _selectedCategory;
  String _searchQuery = '';
  String? _selectedAnalyticsSymbol;
  bool _isDarkMode = true;

  MarketSnapshot? get snapshot => _snapshot;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AssetCategory? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isDarkMode => _isDarkMode;
  bool get isOffline => _snapshot?.isOffline ?? false;

  List<MarketAsset> get allAssets => _snapshot?.assets ?? const [];

  List<MarketAsset> get filteredAssets {
    final query = _searchQuery.trim().toLowerCase();
    return allAssets.where((asset) {
      if (_selectedCategory != null && asset.category != _selectedCategory) {
        return false;
      }
      if (query.isEmpty) return true;
      return asset.symbol.toLowerCase().contains(query) ||
          asset.displayPair.toLowerCase().contains(query) ||
          asset.name.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  MarketAsset? get selectedAnalyticsAsset {
    final assets = allAssets;
    if (assets.isEmpty) return null;
    if (_selectedAnalyticsSymbol != null) {
      for (final asset in assets) {
        if (asset.symbol == _selectedAnalyticsSymbol) return asset;
      }
    }
    return assets.first;
  }

  /// Hydrates cached data instantaneously if present, then fetches live quotes.
  Future<void> initialize() async {
    final cached = await _repository.loadCachedOnly();
    if (cached != null && cached.assets.isNotEmpty) {
      _snapshot = cached;
      _selectedAnalyticsSymbol ??= cached.assets.first.symbol;
      notifyListeners();
    }
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loaded = await _loadMarketSnapshot(forceRefresh: true);
      _snapshot = loaded;
      if (_selectedAnalyticsSymbol == null && loaded.assets.isNotEmpty) {
        _selectedAnalyticsSymbol = loaded.assets.first.symbol;
      }
    } on AppFailure catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Непредвиденная ошибка загрузки данных: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(AssetCategory? category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  void selectAnalyticsAsset(String symbol) {
    if (_selectedAnalyticsSymbol == symbol) return;
    _selectedAnalyticsSymbol = symbol;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  PeriodAnalytics computeAnalytics(
    MarketAsset asset,
    AnalyticsTimeframe timeframe,
  ) {
    return _calculatePeriodAnalytics(
      assetSymbol: asset.symbol,
      candles: asset.candles,
      timeframe: timeframe,
    );
  }
}
