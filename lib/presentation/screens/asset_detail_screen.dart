import 'package:material_ui/material_ui.dart';

import '../../app/theme/terminal_theme.dart';
import '../../core/formatters/number_formatter.dart';
import '../../domain/entities/market_asset.dart';
import '../../domain/entities/period_analytics.dart';
import '../controllers/market_terminal_controller.dart';
import '../widgets/analytics_metric_tile.dart';
import '../widgets/asset_badge.dart';
import '../widgets/candle_chart_widget.dart';

/// TradingView-inspired interactive instrument detail view.
class AssetDetailScreen extends StatefulWidget {
  const AssetDetailScreen({
    super.key,
    required this.asset,
    required this.controller,
    required this.onOpenAnalytics,
  });

  final MarketAsset asset;
  final MarketTerminalController controller;
  final void Function(AnalyticsTimeframe timeframe) onOpenAnalytics;

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  AnalyticsTimeframe _timeframe = AnalyticsTimeframe.month30d;
  ChartDisplayMode _chartMode = ChartDisplayMode.candles;

  @override
  Widget build(BuildContext context) {
    final palette = TerminalTheme.of(context);
    final analytics = widget.controller.computeAnalytics(
      widget.asset,
      _timeframe,
    );
    final isUp = widget.asset.change24hPercent >= 0;
    final trendColor = isUp ? palette.bull : palette.bear;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            AssetBadge(
              symbol: widget.asset.symbol,
              category: widget.asset.category,
              size: 32,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.asset.displayPair,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${widget.asset.name} • ${widget.asset.source}',
                    style: TextStyle(
                      fontSize: 11,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                MarketNumberFormatter.formatPrice(widget.asset.currentPrice),
                style: TerminalTheme.tabular(
                  context,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  widget.asset.quoteCurrency,
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  MarketNumberFormatter.formatPercent(
                    widget.asset.change24hPercent,
                  ),
                  style: TerminalTheme.tabular(
                    context,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: trendColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SegmentedButton<AnalyticsTimeframe>(
                segments: const [
                  ButtonSegment(
                    value: AnalyticsTimeframe.week7d,
                    label: Text('7Д'),
                  ),
                  ButtonSegment(
                    value: AnalyticsTimeframe.twoWeeks14d,
                    label: Text('14Д'),
                  ),
                  ButtonSegment(
                    value: AnalyticsTimeframe.month30d,
                    label: Text('30Д'),
                  ),
                ],
                selected: {_timeframe},
                onSelectionChanged: (s) => setState(() => _timeframe = s.first),
              ),
              const Spacer(),
              SegmentedButton<ChartDisplayMode>(
                segments: const [
                  ButtonSegment(
                    value: ChartDisplayMode.candles,
                    icon: Icon(Icons.candlestick_chart_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: ChartDisplayMode.area,
                    icon: Icon(Icons.show_chart_rounded, size: 16),
                  ),
                ],
                selected: {_chartMode},
                onSelectionChanged: (s) => setState(() => _chartMode = s.first),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CandleChartWidget(
            candles: analytics.points,
            mode: _chartMode,
            height: 250,
            averageLineValue: analytics.isEmpty ? null : analytics.averagePrice,
            smaValues: analytics.smaSeries,
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.9,
            children: [
              AnalyticsMetricTile(
                label: 'Минимум (${_timeframe.shortLabel})',
                value: MarketNumberFormatter.formatPrice(analytics.minPrice),
                valueColor: palette.bear,
              ),
              AnalyticsMetricTile(
                label: 'Максимум (${_timeframe.shortLabel})',
                value: MarketNumberFormatter.formatPrice(analytics.maxPrice),
                valueColor: palette.bull,
              ),
              AnalyticsMetricTile(
                label: 'Среднее (${_timeframe.shortLabel})',
                value:
                    MarketNumberFormatter.formatPrice(analytics.averagePrice),
                valueColor: palette.accent,
              ),
              AnalyticsMetricTile(
                label: 'Тенденция',
                value: analytics.trend.labelRu,
                subtitle: MarketNumberFormatter.formatPercent(
                  analytics.percentChange,
                ),
                valueColor: switch (analytics.trend) {
                  TrendDirection.up => palette.bull,
                  TrendDirection.down => palette.bear,
                  TrendDirection.flat => palette.textSecondary,
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      widget.onOpenAnalytics(AnalyticsTimeframe.week7d),
                  icon: const Icon(Icons.analytics_outlined, size: 18),
                  label: const Text('Аналитика 7Д'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      widget.onOpenAnalytics(AnalyticsTimeframe.month30d),
                  icon: const Icon(Icons.analytics_rounded, size: 18),
                  label: const Text('Аналитика 30Д'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
