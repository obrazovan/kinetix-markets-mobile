import 'market_asset.dart';
import 'market_snapshot.dart';

/// Normalized single unit/currency/asset eligible for cross-asset conversion.
class ConvertibleInstrument {
  const ConvertibleInstrument({
    required this.code,
    required this.name,
    required this.category,
    required this.usdPricePerUnit,
    required this.updatedAt,
  });

  final String code;
  final String name;
  final AssetCategory category;
  final double usdPricePerUnit;
  final DateTime updatedAt;

  /// Derives a complete, deduplicated convertible catalog from a [MarketSnapshot].
  static List<ConvertibleInstrument> catalogFromSnapshot(
    MarketSnapshot snapshot,
  ) {
    final map = <String, ConvertibleInstrument>{};
    final now = snapshot.fetchedAt;

    map['USD'] = ConvertibleInstrument(
      code: 'USD',
      name: 'US Dollar',
      category: AssetCategory.forex,
      usdPricePerUnit: 1.0,
      updatedAt: now,
    );

    double? usdToMdl;
    for (final a in snapshot.assets) {
      if (a.symbol == 'USD/MDL' && a.currentPrice > 0) {
        usdToMdl = a.currentPrice;
      }
    }

    for (final asset in snapshot.assets) {
      switch (asset.category) {
        case AssetCategory.crypto:
        case AssetCategory.stock:
          map[asset.symbol] = ConvertibleInstrument(
            code: asset.symbol,
            name: asset.name,
            category: asset.category,
            usdPricePerUnit: asset.usdEquivalentPrice,
            updatedAt: asset.updatedAt,
          );
        case AssetCategory.forex:
          if (asset.symbol == 'USD/MDL' && asset.currentPrice > 0) {
            map['MDL'] = ConvertibleInstrument(
              code: 'MDL',
              name: 'Moldovan Leu',
              category: AssetCategory.forex,
              usdPricePerUnit: 1.0 / asset.currentPrice,
              updatedAt: asset.updatedAt,
            );
          } else if (asset.symbol.endsWith('/USD')) {
            final base = asset.symbol.split('/').first;
            map[base] = ConvertibleInstrument(
              code: base,
              name: asset.name.split('/').first.trim(),
              category: AssetCategory.forex,
              usdPricePerUnit: asset.currentPrice,
              updatedAt: asset.updatedAt,
            );
          } else if (asset.symbol.startsWith('USD/') &&
              asset.currentPrice > 0) {
            final quote = asset.symbol.split('/').last;
            map[quote] = ConvertibleInstrument(
              code: quote,
              name: asset.name.split('/').last.trim(),
              category: AssetCategory.forex,
              usdPricePerUnit: 1.0 / asset.currentPrice,
              updatedAt: asset.updatedAt,
            );
          } else if (asset.symbol.endsWith('/MDL') &&
              usdToMdl != null &&
              usdToMdl > 0) {
            final base = asset.symbol.split('/').first;
            map.putIfAbsent(
              base,
              () => ConvertibleInstrument(
                code: base,
                name: asset.name.split('/').first.trim(),
                category: AssetCategory.forex,
                usdPricePerUnit: asset.currentPrice / usdToMdl!,
                updatedAt: asset.updatedAt,
              ),
            );
          }
      }
    }

    if (map.containsKey('BTC')) {
      map['USDT'] = ConvertibleInstrument(
        code: 'USDT',
        name: 'Tether USD',
        category: AssetCategory.crypto,
        usdPricePerUnit: 1.0,
        updatedAt: now,
      );
    }

    return map.values.toList(growable: false);
  }
}
