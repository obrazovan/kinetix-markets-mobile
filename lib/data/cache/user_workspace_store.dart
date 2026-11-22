import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/portfolio_holding.dart';

/// Persists user favorites (watchlist) and virtual portfolio positions locally.
class UserWorkspaceStore {
  UserWorkspaceStore({SharedPreferences? prefs}) : _prefs = prefs;

  static const String favoritesKey = 'kinetix_favorites_v1';
  static const String portfolioKey = 'kinetix_portfolio_v1';

  static const List<PortfolioHolding> defaultPortfolio = [
    PortfolioHolding(symbol: 'BTC', quantity: 0.12),
    PortfolioHolding(symbol: 'AAPL', quantity: 5.0),
    PortfolioHolding(symbol: 'EUR/USD', quantity: 1000.0),
  ];

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<Set<String>> loadFavorites() async {
    try {
      final prefs = await _getPrefs();
      final list = prefs.getStringList(favoritesKey);
      if (list == null) return {'BTC', 'AAPL', 'EUR/USD', 'USD/MDL'};
      return list.toSet();
    } catch (_) {
      return {'BTC', 'AAPL', 'EUR/USD', 'USD/MDL'};
    }
  }

  Future<void> saveFavorites(Set<String> symbols) async {
    final prefs = await _getPrefs();
    await prefs.setStringList(favoritesKey, symbols.toList()..sort());
  }

  Future<List<PortfolioHolding>> loadPortfolio() async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(portfolioKey);
      if (raw == null) return defaultPortfolio;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return defaultPortfolio;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PortfolioHolding.fromJson)
          .where((h) => h.quantity > 0)
          .toList(growable: false);
    } catch (_) {
      return defaultPortfolio;
    }
  }

  Future<void> savePortfolio(List<PortfolioHolding> holdings) async {
    final prefs = await _getPrefs();
    final encoded = jsonEncode(
      holdings.map((h) => h.toJson()).toList(growable: false),
    );
    await prefs.setString(portfolioKey, encoded);
  }
}
