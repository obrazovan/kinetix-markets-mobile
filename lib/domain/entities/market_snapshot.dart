import 'market_asset.dart';

/// Complete persisted or live market snapshot across all asset classes.
class MarketSnapshot {
  const MarketSnapshot({
    required this.assets,
    required this.fetchedAt,
    required this.isOffline,
    this.warnings = const [],
  });

  factory MarketSnapshot.fromJson(Map<String, dynamic> json) {
    final rawAssets = json['assets'] as List<dynamic>? ?? const [];
    final rawWarnings = json['warnings'] as List<dynamic>? ?? const [];
    return MarketSnapshot(
      assets: rawAssets
          .whereType<Map<String, dynamic>>()
          .map(MarketAsset.fromJson)
          .toList(growable: false),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      isOffline: json['isOffline'] as bool? ?? false,
      warnings: rawWarnings.whereType<String>().toList(growable: false),
    );
  }

  final List<MarketAsset> assets;
  final DateTime fetchedAt;
  final bool isOffline;
  final List<String> warnings;

  MarketSnapshot copyWith({
    List<MarketAsset>? assets,
    DateTime? fetchedAt,
    bool? isOffline,
    List<String>? warnings,
  }) {
    return MarketSnapshot(
      assets: assets ?? this.assets,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      isOffline: isOffline ?? this.isOffline,
      warnings: warnings ?? this.warnings,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'assets': assets.map((a) => a.toJson()).toList(growable: false),
        'fetchedAt': fetchedAt.toIso8601String(),
        'isOffline': isOffline,
        'warnings': warnings,
      };
}
