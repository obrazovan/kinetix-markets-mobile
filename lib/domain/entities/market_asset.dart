import 'candle_point.dart';

/// Market asset categories represented in the terminal.
enum AssetCategory {
  stock('Акции', 'Stocks'),
  crypto('Крипто', 'Crypto'),
  forex('Forex', 'Forex');

  const AssetCategory(this.labelRu, this.labelEn);

  final String labelRu;
  final String labelEn;
}

/// Unified financial instrument across Stocks, Crypto, and Forex.
class MarketAsset {
  const MarketAsset({
    required this.symbol,
    required this.displayPair,
    required this.name,
    required this.category,
    required this.quoteCurrency,
    required this.currentPrice,
    required this.usdEquivalentPrice,
    required this.change24hPercent,
    required this.source,
    required this.updatedAt,
    required this.candles,
  });

  factory MarketAsset.fromJson(Map<String, dynamic> json) {
    final catName = json['category'] as String? ?? 'forex';
    final category = AssetCategory.values.firstWhere(
      (c) => c.name == catName,
      orElse: () => AssetCategory.forex,
    );
    final rawCandles = json['candles'] as List<dynamic>? ?? const [];
    return MarketAsset(
      symbol: json['symbol'] as String,
      displayPair: json['displayPair'] as String,
      name: json['name'] as String,
      category: category,
      quoteCurrency: json['quoteCurrency'] as String,
      currentPrice: (json['currentPrice'] as num).toDouble(),
      usdEquivalentPrice: (json['usdEquivalentPrice'] as num).toDouble(),
      change24hPercent: (json['change24hPercent'] as num).toDouble(),
      source: json['source'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      candles: rawCandles
          .whereType<Map<String, dynamic>>()
          .map(CandlePoint.fromJson)
          .toList(growable: false),
    );
  }

  final String symbol;
  final String displayPair;
  final String name;
  final AssetCategory category;
  final String quoteCurrency;
  final double currentPrice;
  final double usdEquivalentPrice;
  final double change24hPercent;
  final String source;
  final DateTime updatedAt;
  final List<CandlePoint> candles;

  MarketAsset copyWith({
    double? currentPrice,
    double? usdEquivalentPrice,
    double? change24hPercent,
    DateTime? updatedAt,
    List<CandlePoint>? candles,
  }) {
    return MarketAsset(
      symbol: symbol,
      displayPair: displayPair,
      name: name,
      category: category,
      quoteCurrency: quoteCurrency,
      currentPrice: currentPrice ?? this.currentPrice,
      usdEquivalentPrice: usdEquivalentPrice ?? this.usdEquivalentPrice,
      change24hPercent: change24hPercent ?? this.change24hPercent,
      source: source,
      updatedAt: updatedAt ?? this.updatedAt,
      candles: candles ?? this.candles,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'symbol': symbol,
        'displayPair': displayPair,
        'name': name,
        'category': category.name,
        'quoteCurrency': quoteCurrency,
        'currentPrice': currentPrice,
        'usdEquivalentPrice': usdEquivalentPrice,
        'change24hPercent': change24hPercent,
        'source': source,
        'updatedAt': updatedAt.toIso8601String(),
        'candles': candles.map((c) => c.toJson()).toList(growable: false),
      };
}
