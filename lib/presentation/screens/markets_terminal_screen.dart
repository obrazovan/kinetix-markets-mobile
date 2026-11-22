import 'package:material_ui/material_ui.dart';

import '../../app/theme/terminal_theme.dart';
import '../../core/formatters/number_formatter.dart';
import '../../domain/entities/market_asset.dart';
import '../controllers/market_terminal_controller.dart';
import '../widgets/asset_badge.dart';
import '../widgets/offline_status_banner.dart';
import '../widgets/sparkline_painter.dart';
import 'asset_detail_screen.dart';

/// Main TradingView-style market watchlist screen across Stocks, Crypto & Forex.
class MarketsTerminalScreen extends StatelessWidget {
  const MarketsTerminalScreen({
    super.key,
    required this.controller,
    required this.onOpenComparison,
  });

  final MarketTerminalController controller;
  final void Function(String symbol, {required bool monthly}) onOpenComparison;

  @override
  Widget build(BuildContext context) {
    final palette = TerminalTheme.of(context);
    final snapshot = controller.snapshot;

    if (controller.isLoading && snapshot == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: palette.accent),
            const SizedBox(height: 14),
            Text(
              'Загрузка котировок Stocks · Crypto · Forex...',
              style: TextStyle(color: palette.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (snapshot == null && controller.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: palette.warning),
              const SizedBox(height: 12),
              Text(
                controller.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: controller.refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Повторить загрузку'),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = controller.filteredAssets;
    final pulseAssets = _pickPulseHighlights(controller.allAssets);

    return RefreshIndicator(
      color: palette.accent,
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          OfflineStatusBanner(
            isOffline: controller.isOffline,
            fetchedAt: snapshot?.fetchedAt,
            warnings: snapshot?.warnings ?? const [],
            onRetry: controller.refresh,
          ),
          if (pulseAssets.isNotEmpty) ...[
            Text(
              'Пульс рынков',
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 102,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pulseAssets.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) => _PulseHighlightCard(
                  asset: pulseAssets[index],
                  onTap: () => _openDetail(context, pulseAssets[index]),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            onChanged: controller.setSearchQuery,
            style: TextStyle(color: palette.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Поиск тикера (BTC, AAPL, EUR/USD, MDL)...',
              hintStyle: TextStyle(color: palette.textSecondary, fontSize: 13),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: palette.textSecondary,
                size: 20,
              ),
              filled: true,
              fillColor: palette.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.accent, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CategoryChip(
                  label: 'Все (${controller.allAssets.length})',
                  selected: controller.selectedCategory == null,
                  onTap: () => controller.setCategory(null),
                ),
                const SizedBox(width: 8),
                ...AssetCategory.values.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CategoryChip(
                      label: cat.labelRu,
                      selected: controller.selectedCategory == cat,
                      onTap: () => controller.setCategory(cat),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.border),
              ),
              alignment: Alignment.center,
              child: Text(
                'Инструменты по запросу не найдены',
                style: TextStyle(color: palette.textSecondary, fontSize: 13),
              ),
            )
          else
            ...filtered.map(
              (asset) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _WatchlistRowCard(
                  asset: asset,
                  onTap: () => _openDetail(context, asset),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, MarketAsset asset) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AssetDetailScreen(
          asset: asset,
          controller: controller,
          onOpenComparison: (monthly) {
            Navigator.of(context).pop();
            onOpenComparison(asset.symbol, monthly: monthly);
          },
        ),
      ),
    );
  }

  static List<MarketAsset> _pickPulseHighlights(List<MarketAsset> assets) {
    const preferred = ['BTC', 'AAPL', 'EUR/USD', 'USD/MDL', 'NVDA', 'ETH'];
    final picked = <MarketAsset>[];
    for (final sym in preferred) {
      for (final a in assets) {
        if (a.symbol == sym) {
          picked.add(a);
          break;
        }
      }
    }
    return picked.isNotEmpty ? picked : assets.take(4).toList(growable: false);
  }
}

class _PulseHighlightCard extends StatelessWidget {
  const _PulseHighlightCard({required this.asset, required this.onTap});

  final MarketAsset asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TerminalTheme.of(context);
    final isUp = asset.change24hPercent >= 0;
    final trendColor = isUp ? palette.bull : palette.bear;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 152,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    asset.displayPair,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    MarketNumberFormatter.formatPercent(asset.change24hPercent),
                    style: TerminalTheme.tabular(
                      context,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: trendColor,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${MarketNumberFormatter.formatPrice(asset.currentPrice)} ${asset.quoteCurrency}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TerminalTheme.tabular(
                context,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            SparklineChart(
              candles: asset.candles,
              color: trendColor,
              width: 126,
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TerminalTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? palette.accent.withValues(alpha: 0.16)
              : palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? palette.accent : palette.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? palette.accent : palette.textSecondary,
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _WatchlistRowCard extends StatelessWidget {
  const _WatchlistRowCard({required this.asset, required this.onTap});

  final MarketAsset asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TerminalTheme.of(context);
    final isUp = asset.change24hPercent >= 0;
    final trendColor = isUp ? palette.bull : palette.bear;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            AssetBadge(symbol: asset.symbol, category: asset.category),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          asset.displayPair,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surfaceElevated,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          asset.source,
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    asset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SparklineChart(
              candles: asset.candles,
              color: trendColor,
              width: 58,
              height: 26,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  MarketNumberFormatter.formatPrice(asset.currentPrice),
                  style: TerminalTheme.tabular(
                    context,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    MarketNumberFormatter.formatPercent(asset.change24hPercent),
                    style: TerminalTheme.tabular(
                      context,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: trendColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
