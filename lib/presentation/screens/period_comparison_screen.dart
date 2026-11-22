import 'package:material_ui/material_ui.dart';

import '../../app/theme/terminal_theme.dart';
import '../../core/formatters/number_formatter.dart';
import '../../domain/entities/market_asset.dart';
import '../../domain/entities/period_analytics.dart';
import '../controllers/market_terminal_controller.dart';
import '../widgets/analytics_metric_tile.dart';
import '../widgets/asset_badge.dart';
import '../widgets/candle_chart_widget.dart';
import '../widgets/offline_status_banner.dart';

/// Mandatory 7-Day (Weekly) and 30-Day (Monthly) comparison analytics screen.
class PeriodComparisonScreen extends StatefulWidget {
  const PeriodComparisonScreen({
    super.key,
    required this.timeframe,
    required this.controller,
  });

  final AnalyticsTimeframe timeframe;
  final MarketTerminalController controller;

  @override
  State<PeriodComparisonScreen> createState() => _PeriodComparisonScreenState();
}

class _PeriodComparisonScreenState extends State<PeriodComparisonScreen> {
  ChartDisplayMode _chartMode = ChartDisplayMode.area;

  @override
  Widget build(BuildContext context) {
    final palette = TerminalTheme.of(context);
    final assets = widget.controller.allAssets;
    final selected = widget.controller.selectedAnalyticsAsset;
    final snapshot = widget.controller.snapshot;

    if (assets.isEmpty || selected == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            widget.controller.isLoading
                ? 'Загрузка исторических данных...'
                : 'Нет данных для расчёта аналитики. Попробуйте обновить котировки.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    final analytics = widget.controller.computeAnalytics(
      selected,
      widget.timeframe,
    );
    final weeklyRef = widget.timeframe == AnalyticsTimeframe.month30d
        ? widget.controller.computeAnalytics(
            selected,
            AnalyticsTimeframe.week7d,
          )
        : null;

    final trendColor = switch (analytics.trend) {
      TrendDirection.up => palette.bull,
      TrendDirection.down => palette.bear,
      TrendDirection.flat => palette.textSecondary,
    };

    final trendIcon = switch (analytics.trend) {
      TrendDirection.up => Icons.trending_up_rounded,
      TrendDirection.down => Icons.trending_down_rounded,
      TrendDirection.flat => Icons.trending_flat_rounded,
    };

    return RefreshIndicator(
      color: palette.accent,
      onRefresh: widget.controller.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          OfflineStatusBanner(
            isOffline: widget.controller.isOffline,
            fetchedAt: snapshot?.fetchedAt,
            warnings: snapshot?.warnings ?? const [],
            onRetry: widget.controller.refresh,
          ),
          Text(
            widget.timeframe == AnalyticsTimeframe.week7d
                ? 'Сравнение за неделю (7 дней)'
                : 'Сравнение за месяц (30 дней)',
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Анализ динамики, экстремумов и тренда по выбранному инструменту',
            style: TextStyle(color: palette.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: assets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final asset = assets[index];
                final isSelected = asset.symbol == selected.symbol;
                return _AssetSelectorPill(
                  asset: asset,
                  selected: isSelected,
                  onTap: () =>
                      widget.controller.selectAnalyticsAsset(asset.symbol),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          _HeroTrendCard(
            asset: selected,
            analytics: analytics,
            trendColor: trendColor,
            trendIcon: trendIcon,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'График динамики (${analytics.points.length} т.)',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              SegmentedButton<ChartDisplayMode>(
                segments: const [
                  ButtonSegment(
                    value: ChartDisplayMode.area,
                    label: Text('Линия'),
                  ),
                  ButtonSegment(
                    value: ChartDisplayMode.candles,
                    label: Text('Свечи'),
                  ),
                ],
                selected: {_chartMode},
                onSelectionChanged: (s) => setState(() => _chartMode = s.first),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CandleChartWidget(
            candles: analytics.points,
            mode: _chartMode,
            height: 230,
            averageLineValue: analytics.isEmpty ? null : analytics.averagePrice,
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.75,
            children: [
              AnalyticsMetricTile(
                label: 'Минимум за период',
                value:
                    '${MarketNumberFormatter.formatPrice(analytics.minPrice)} ${selected.quoteCurrency}',
                valueColor: palette.bear,
                icon: Icons.south_rounded,
              ),
              AnalyticsMetricTile(
                label: 'Максимум за период',
                value:
                    '${MarketNumberFormatter.formatPrice(analytics.maxPrice)} ${selected.quoteCurrency}',
                valueColor: palette.bull,
                icon: Icons.north_rounded,
              ),
              AnalyticsMetricTile(
                label: 'Среднее значение',
                value:
                    '${MarketNumberFormatter.formatPrice(analytics.averagePrice)} ${selected.quoteCurrency}',
                subtitle: 'Пунктирная линия на графике',
                valueColor: palette.accent,
                icon: Icons.horizontal_rule_rounded,
              ),
              AnalyticsMetricTile(
                label: 'Изменение (абс. / %)',
                value: MarketNumberFormatter.formatSignedDelta(
                  analytics.absoluteChange,
                ),
                subtitle: MarketNumberFormatter.formatPercent(
                  analytics.percentChange,
                ),
                valueColor: trendColor,
                icon: Icons.compare_arrows_rounded,
              ),
              AnalyticsMetricTile(
                label: 'Направление тенденции',
                value: analytics.trend.labelRu,
                subtitle:
                    'Старт: ${MarketNumberFormatter.formatPrice(analytics.startPrice)}',
                valueColor: trendColor,
                icon: trendIcon,
              ),
              AnalyticsMetricTile(
                label: 'Размах волатильности',
                value: MarketNumberFormatter.formatPercent(
                  analytics.volatilityPercent,
                  includeSign: false,
                ),
                subtitle:
                    'Финиш: ${MarketNumberFormatter.formatPrice(analytics.endPrice)}',
                icon: Icons.waves_rounded,
              ),
            ],
          ),
          if (weeklyRef != null && !weeklyRef.isEmpty) ...[
            const SizedBox(height: 14),
            _MonthlyVsWeeklyBanner(
              weekly: weeklyRef,
              monthly: analytics,
              quoteCurrency: selected.quoteCurrency,
            ),
          ],
        ],
      ),
    );
  }
}

class _AssetSelectorPill extends StatelessWidget {
  const _AssetSelectorPill({
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final MarketAsset asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TerminalTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? palette.accent.withValues(alpha: 0.16)
              : palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? palette.accent : palette.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AssetBadge(
              symbol: asset.symbol,
              category: asset.category,
              size: 24,
            ),
            const SizedBox(width: 7),
            Text(
              asset.displayPair,
              style: TextStyle(
                color: selected ? palette.accent : palette.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroTrendCard extends StatelessWidget {
  const _HeroTrendCard({
    required this.asset,
    required this.analytics,
    required this.trendColor,
    required this.trendIcon,
  });

  final MarketAsset asset;
  final PeriodAnalytics analytics;
  final Color trendColor;
  final IconData trendIcon;

  @override
  Widget build(BuildContext context) {
    final palette = TerminalTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          AssetBadge(
            symbol: asset.symbol,
            category: asset.category,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.displayPair,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${MarketNumberFormatter.formatPrice(analytics.endPrice)} ${asset.quoteCurrency}',
                  style: TerminalTheme.tabular(
                    context,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: trendColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trendIcon, size: 16, color: trendColor),
                    const SizedBox(width: 5),
                    Text(
                      analytics.trend.labelRu,
                      style: TextStyle(
                        color: trendColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${MarketNumberFormatter.formatSignedDelta(analytics.absoluteChange)} (${MarketNumberFormatter.formatPercent(analytics.percentChange)})',
                style: TerminalTheme.tabular(
                  context,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: trendColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthlyVsWeeklyBanner extends StatelessWidget {
  const _MonthlyVsWeeklyBanner({
    required this.weekly,
    required this.monthly,
    required this.quoteCurrency,
  });

  final PeriodAnalytics weekly;
  final PeriodAnalytics monthly;
  final String quoteCurrency;

  @override
  Widget build(BuildContext context) {
    final palette = TerminalTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Icon(Icons.insights_rounded, color: palette.accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Контекст: 7Д vs 30Д',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '7Д: ${weekly.trend.labelRu} (${MarketNumberFormatter.formatPercent(weekly.percentChange)}) • '
                  '30Д: ${monthly.trend.labelRu} (${MarketNumberFormatter.formatPercent(monthly.percentChange)})',
                  style: TerminalTheme.tabular(
                    context,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
