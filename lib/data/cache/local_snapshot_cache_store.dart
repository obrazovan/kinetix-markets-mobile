import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/market_snapshot.dart';
import '../../domain/repositories/snapshot_cache_store.dart';

/// Persistent local snapshot storage backed by SharedPreferences.
class LocalSnapshotCacheStore implements SnapshotCacheStore {
  LocalSnapshotCacheStore({SharedPreferences? prefs}) : _prefs = prefs;

  static const String cacheKey = 'kinetix_markets_snapshot_v1';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<void> saveSnapshot(MarketSnapshot snapshot) async {
    try {
      final prefs = await _getPrefs();
      final encoded = jsonEncode(snapshot.toJson());
      await prefs.setString(cacheKey, encoded);
    } catch (e) {
      throw CacheFailure('Ошибка сохранения локального кэша', e.toString());
    }
  }

  @override
  Future<MarketSnapshot?> loadSnapshot() async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(cacheKey);
      if (raw == null || raw.trim().isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return MarketSnapshot.fromJson(decoded);
    } catch (_) {
      // Corrupted cache must never crash app startup.
      return null;
    }
  }

  @override
  Future<void> clear() async {
    final prefs = await _getPrefs();
    await prefs.remove(cacheKey);
  }
}
