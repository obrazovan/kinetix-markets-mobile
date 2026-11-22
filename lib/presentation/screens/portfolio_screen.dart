import 'package:material_ui/material_ui.dart';

import '../../app/theme/terminal_theme.dart';
import '../../core/formatters/number_formatter.dart';
import '../../core/utils/input_validator.dart';
import '../../domain/entities/market_asset.dart';
import '../controllers/market_terminal_controller.dart';
import '../widgets/asset_badge.dart';
import '../widgets/offline_status_banner.dart';

/// Interactive virtual portfolio tracker with multi-currency valuation.
class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({
    super.key,
    required this.controller,
  });

  final MarketTerminalController controller;

  @override
  Widget build(BuildContext context) {
    final palette = TerminalTheme.of(context);
    final snapshot = controller.snapshot;
    final holdings = controller.holdings;
    final fxRate = controller.usdToPortfolioCurrencyRate;
    final currency = controller.portfolioDisplayCurrency;

    final entries = <({MarketAsset asset, double qty, double valueDisplay})>[];
    var totalDisplayValue = 0.0;
    var weightedDayChange = 0.0;

    for (final holding in holdings) {
      final asset = controller.findAsset(holding.symbol);
      if (asset == null) continue;
      final value = holding.quantity * asset.usdEquivalentPrice * fxRate;
      totalDisplayValue += value;
      weightedDayChange += value * (asset.change24hPercent / 100.0);
      entries.add((asset: asset, qty: holding.quantity, valueDisplay: value));
    }

    final dayPct =
        totalDisplayValue > 0 ? (weightedDayChange / totalDisplayValue) * 100 : 0.0;
    final dayColor = dayPct >= 0 ? palette.bull : palette.bear;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        OfflineStatusBanner(
          isOffline: controller.isOffline,
          fetchedAt: snapshot?.fetchedAt,
          warnings: snapshot?.warnings ?? const [],
          onRetry: controller.refresh,
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                'Инвестиционный портфель',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'USD', label: Text('USD')),
                ButtonSegment(value: 'EUR', label: Text('EUR')),
                ButtonSegment(value: 'MDL', label: Text('MDL')),
              ],
              selected: {currency},
              onSelectionChanged: (s) =>
                  controller.setPortfolioDisplayCurrency(s.first),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Оценка активов',
                style: TextStyle(color: palette.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                '${MarketNumberFormatter.formatPrice(totalDisplayValue)} $currency',
                style: TerminalTheme.tabular(
                  context,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'За 24ч: ',
                    style: TextStyle(color: palette.textSecondary, fontSize: 12),
                  ),
                  Text(
                    '${MarketNumberFormatter.formatSignedDelta(weightedDayChange)} $currency (${MarketNumberFormatter.formatPercent(dayPct)})',
                    style: TerminalTheme.tabular(
                      context,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: dayColor,
                    ),
                  ),
                ],
              ),
              if (entries.isNotEmpty && totalDisplayValue > 0) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 9,
                    child: Row(
                      children: entries.asMap().entries.map((entry) {
                        final share = entry.value.valueDisplay / totalDisplayValue;
                        final flex = (share * 1000).round().clamp(1, 1000);
                        return Expanded(
                          flex: flex,
                          child: Container(
                            color: _sliceColor(entry.key, palette),
                          ),
                        );
                      }).toList(growable: false),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              'Позиции (${entries.length})',
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: controller.allAssets.isEmpty
                  ? null
                  : () => _showAddDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Добавить актив'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.border),
            ),
            alignment: Alignment.center,
            child: Text(
              'Портфель пуст. Добавьте акции, криптовалюту или Forex-позиции.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary, fontSize: 13),
            ),
          )
        else
          ...entries.map((item) {
            final sharePct = totalDisplayValue > 0
                ? (item.valueDisplay / totalDisplayValue) * 100.0
                : 0.0;
            final chgColor =
                item.asset.change24hPercent >= 0 ? palette.bull : palette.bear;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  children: [
                    AssetBadge(
                      symbol: item.asset.symbol,
                      category: item.asset.category,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.asset.displayPair,
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),
                          Text(
                            '${MarketNumberFormatter.formatConvertedAmount(item.qty)} ед. · ${sharePct.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${MarketNumberFormatter.formatPrice(item.valueDisplay)} $currency',
                          style: TerminalTheme.tabular(
                            context,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          MarketNumberFormatter.formatPercent(
                            item.asset.change24hPercent,
                          ),
                          style: TerminalTheme.tabular(
                            context,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: chgColor,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      tooltip: 'Удалить позицию',
                      onPressed: () =>
                          controller.removeHolding(item.asset.symbol),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  static Color _sliceColor(int idx, TerminalPalette p) {
    const paletteColors = [
      Color(0xFF38BDF8),
      Color(0xFF00D084),
      Color(0xFFF5A623),
      Color(0xFFA855F7),
      Color(0xFFFF4D6A),
    ];
    return paletteColors[idx % paletteColors.length];
  }

  Future<void> _showAddDialog(BuildContext context) async {
    var selectedSymbol = controller.allAssets.first.symbol;
    final qtyCtrl = TextEditingController(text: '1');
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              title: const Text('Добавить позицию'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedSymbol,
                    decoration: const InputDecoration(labelText: 'Инструмент'),
                    items: controller.allAssets
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.symbol,
                            child: Text('${a.displayPair} (${a.name})'),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedSymbol = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Количество',
                      errorText: error,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () {
                    final check = InputValidator.validateAmount(qtyCtrl.text);
                    if (!check.isValid || check.parsedValue == null) {
                      setModalState(() => error = check.errorMessage);
                      return;
                    }
                    controller.addOrUpdateHolding(
                      selectedSymbol,
                      check.parsedValue!,
                    );
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
    qtyCtrl.dispose();
  }
}
