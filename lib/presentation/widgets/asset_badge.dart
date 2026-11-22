import 'package:material_ui/material_ui.dart';

import '../../domain/entities/market_asset.dart';

/// Crisp geometric monogram badge uniquely styled per asset class and symbol.
class AssetBadge extends StatelessWidget {
  const AssetBadge({
    super.key,
    required this.symbol,
    required this.category,
    this.size = 40,
  });

  final String symbol;
  final AssetCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _accentForSymbol(symbol, category);
    final shortText = _shortTag(symbol);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: color.withValues(alpha: 0.42),
          width: 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        shortText,
        style: TextStyle(
          color: color,
          fontSize: shortText.length >= 4 ? size * 0.26 : size * 0.31,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  static String _shortTag(String symbol) {
    if (symbol.contains('/')) {
      return symbol.split('/').first;
    }
    return symbol.length > 4 ? symbol.substring(0, 4) : symbol;
  }

  static Color _accentForSymbol(String symbol, AssetCategory category) {
    switch (symbol) {
      case 'BTC':
        return const Color(0xFFF7931A);
      case 'ETH':
        return const Color(0xFF627EEA);
      case 'SOL':
        return const Color(0xFF14F195);
      case 'TON':
        return const Color(0xFF0098EA);
      case 'BNB':
        return const Color(0xFFF3BA2F);
      case 'NVDA':
        return const Color(0xFF76B900);
      case 'TSLA':
        return const Color(0xFFE82127);
      case 'AAPL':
        return const Color(0xFF94A3B8);
      case 'USD/MDL':
      case 'EUR/MDL':
      case 'MDL':
        return const Color(0xFFEAB308);
      default:
        return switch (category) {
          AssetCategory.stock => const Color(0xFF38BDF8),
          AssetCategory.crypto => const Color(0xFFA855F7),
          AssetCategory.forex => const Color(0xFF10B981),
        };
    }
  }
}
