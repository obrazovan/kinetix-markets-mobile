import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/failures.dart';
import '../../data/cache/user_workspace_store.dart';
import '../../domain/entities/market_asset.dart';
import '../../domain/entities/market_snapshot.dart';
import '../../domain/entities/period_analytics.dart';
import '../../domain/entities/portfolio_holding.dart';
import '../../domain/repositories/market_repository.dart';
import '../../domain/usecases/calculate_period_analytics.dart';
import '../../domain/usecases/load_market_snapshot.dart';

/// State controller for Markets Terminal, Unified Analytics, and Portfolio.
class MarketTerminalController extends ChangeNotifier {
  MarketTerminalController({
    required LoadMarketSnapshot loadMarketSnapshot,
    required CalculatePeriodAnalytics calculatePeriodAnalytics,
    required MarketRepository repository,
    UserWorkspaceStore? workspaceStore,
  })  : _loadMarketSnapshot = loadMarketSnapshot,
        _calculatePeriodAnalytics = calculatePeriodAnalytics,
        _repository = repository,
        _workspaceStore = workspaceStore ?? UserWorkspaceStore();

  final LoadMarketSnapshot _loadMarketSnapshot;
  final CalculatePeriodAnalytics _calculatePeriodAnalytics;
  final MarketRepository _repository;
  final UserWorkspaceStore _workspaceStore;

  MarketSnapshot? _snapshot;
  bool _isLoading = false;
  String? _errorMessage;
  AssetCategory? _selectedCategory;
  bool _favoritesOnly = false;
  String _searchQuery = '';
  String? _selectedAnalyticsSymbol;
  AnalyticsTimeframe _selectedTimeframe = AnalyticsTimeframe.week7d;
  String? _compareSymbol;
  bool _isDarkMode = true;
  Set<String> _favorites = {'BTC', 'AAPL', 'EUR/USD', 'USD/MDL'};
  List<PortfolioHolding> _holdings = UserWorkspaceStore.defaultPortfolio;
  String _portfolioDisplayCurrency = 'USD';

  MarketSnapshot? get snapshot => _snapshot;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AssetCategory? get selectedCategory => _selectedCategory;
  bool get favoritesOnly => _favoritesOnly;
  String get searchQuery => _searchQuery;
  bool get isDarkMode => _isDarkMode;
  bool get isOffline => _snapshot?.isOffline ?? false;
  AnalyticsTimeframe get selectedTimeframe => _selectedTimeframe;
  String? get compareSymbol => _compareSymbol;
  Set<String> get favorites => _favorites;
  List<PortfolioHolding> get holdings => _holdings;
  String get portfolioDisplayCurrency => _portfolioDisplayCurrency;

  List<MarketAsset> get allAssets => _snapshot?.assets ?? const [];

  bool isFavorite(String symbol) => _favorites.contains(symbol);

  List<MarketAsset> get filteredAssets {
    final query = _searchQuery.trim().toLowerCase();
    return allAssets.where((asset) {
      if (_favoritesOnly && !_favorites.contains(asset.symbol)) {
        return false;
      }
      if (_selectedCategory != null && asset.category != _selectedCategory) {
        return false;
      }
      if (query.isEmpty) return true;
      return asset.symbol.toLowerCase().contains(query) ||
          asset.displayPair.toLowerCase().contains(query) ||
          asset.name.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  MarketAsset? findAsset(String? symbol) {
    if (symbol == null) return null;
    for (final asset in allAssets) {
      if (asset.symbol == symbol) return asset;
    }
    return null;
  }

  MarketAsset? get selectedAnalyticsAsset {
    final assets = allAssets;
    if (assets.isEmpty) return null;
    return findAsset(_selectedAnalyticsSymbol) ?? assets.first;
  }

  MarketAsset? get compareAsset {
    final primary = selectedAnalyticsAsset;
    if (primary == null || allAssets.length < 2) return null;
    final explicit = findAsset(_compareSymbol);
    if (explicit != null && explicit.symbol != primary.symbol) return explicit;
    for (final a in allAssets) {
      if (a.symbol != primary.symbol) return a;
    }
    return null;
  }

  /// Hydrates workspace prefs & cached snapshot, then refreshes live quotes.
  Future<void> initialize() async {
    try {
      _favorites = await _workspaceStore.loadFavorites();
      _holdings = await _workspaceStore.loadPortfolio();
    } catch (_) {
      // Safe fallback to defaults in tests without mock SharedPreferences.
    }

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
    if (_selectedCategory == category && !_favoritesOnly) return;
    _selectedCategory = category;
    _favoritesOnly = false;
    notifyListeners();
  }

  void toggleFavoritesFilter() {
    _favoritesOnly = !_favoritesOnly;
    if (_favoritesOnly) {
      _selectedCategory = null;
    }
    notifyListeners();
  }

  void toggleFavorite(String symbol) {
    final next = Set<String>.from(_favorites);
    if (next.contains(symbol)) {
      next.remove(symbol);
    } else {
      next.add(symbol);
    }
    _favorites = next;
    notifyListeners();
    unawaited(_workspaceStore.saveFavorites(next).catchError((_) {}));
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

  void selectTimeframe(AnalyticsTimeframe timeframe) {
    if (_selectedTimeframe == timeframe) return;
    _selectedTimeframe = timeframe;
    notifyListeners();
  }

  void selectCompareAsset(String? symbol) {
    if (_compareSymbol == symbol) return;
    _compareSymbol = symbol;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setPortfolioDisplayCurrency(String code) {
    if (_portfolioDisplayCurrency == code) return;
    _portfolioDisplayCurrency = code;
    notifyListeners();
  }

  void addOrUpdateHolding(String symbol, double quantity) {
    if (quantity <= 0) return;
    final next = List<PortfolioHolding>.from(_holdings);
    final idx = next.indexWhere((h) => h.symbol == symbol);
    if (idx >= 0) {
      next[idx] = PortfolioHolding(symbol: symbol, quantity: quantity);
    } else {
      next.add(PortfolioHolding(symbol: symbol, quantity: quantity));
    }
    _holdings = next;
    notifyListeners();
    unawaited(_workspaceStore.savePortfolio(next).catchError((_) {}));
  }

  void removeHolding(String symbol) {
    final next = _holdings.where((h) => h.symbol != symbol).toList(growable: false);
    _holdings = next;
    notifyListeners();
    unawaited(_workspaceStore.savePortfolio(next).catchError((_) {}));
  }

  /// Conversion multiplier from 1 USD into [portfolioDisplayCurrency].
  double get usdToPortfolioCurrencyRate {
    switch (_portfolioDisplayCurrency) {
      case 'EUR':
        final eurUsd = findAsset('EUR/USD')?.currentPrice;
        return (eurUsd != null && eurUsd > 0) ? (1.0 / eurUsd) : 0.92;
      case 'MDL':
        final usdMdl = findAsset('USD/MDL')?.currentPrice;
        return (usdMdl != null && usdMdl > 0) ? usdMdl : 18.0;
      default:
        return 1.0;
    }
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
