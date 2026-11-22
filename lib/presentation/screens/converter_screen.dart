import 'package:material_ui/material_ui.dart';

import '../../app/theme/terminal_theme.dart';
import '../../core/formatters/number_formatter.dart';
import '../../domain/entities/convertible_instrument.dart';
import '../../domain/entities/market_asset.dart';
import '../controllers/converter_controller.dart';
import '../controllers/market_terminal_controller.dart';
import '../widgets/asset_badge.dart';
import '../widgets/offline_status_banner.dart';

/// Multi-asset exchange converter across Forex, Crypto, and Stocks.
class ConverterScreen extends StatefulWidget {
  const ConverterScreen({
    super.key,
    required this.terminalController,
    required this.converterController,
  });

  final MarketTerminalController terminalController;
  final ConverterController converterController;

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.converterController.rawAmount,
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = TerminalTheme.of(context);
    final ctrl = widget.converterController;
    final snapshot = widget.terminalController.snapshot;
    final result = ctrl.result;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        OfflineStatusBanner(
          isOffline: widget.terminalController.isOffline,
          fetchedAt: snapshot?.fetchedAt,
          warnings: snapshot?.warnings ?? const [],
          onRetry: widget.terminalController.refresh,
        ),
        Text(
          'Мультивалютный конвертер',
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Кросс-конвертация Forex · Криптовалюты · Акции через единую базу USD',
          style: TextStyle(color: palette.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Сумма',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                key: const ValueKey('converter_amount_field'),
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: TerminalTheme.tabular(
                  context,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
                onChanged: ctrl.updateAmount,
                decoration: InputDecoration(
                  hintText: 'Например: 100 или 0,25',
                  hintStyle: TextStyle(
                    color: palette.textSecondary.withValues(alpha: 0.6),
                    fontSize: 16,
                  ),
                  errorText: ctrl.validation.isValid
                      ? null
                      : ctrl.validation.errorMessage,
                  filled: true,
                  fillColor: palette.surfaceElevated,
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
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _InstrumentPickerTile(
                      label: 'Из',
                      instrument: ctrl.fromInstrument,
                      fallbackCode: ctrl.fromCode,
                      onTap: () => _pickInstrument(
                        context,
                        title: 'Исходный актив',
                        catalog: ctrl.catalog,
                        onSelected: ctrl.selectFrom,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: IconButton.filledTonal(
                      key: const ValueKey('converter_swap_button'),
                      onPressed: ctrl.swap,
                      icon: const Icon(Icons.swap_horiz_rounded),
                      tooltip: 'Поменять местами',
                    ),
                  ),
                  Expanded(
                    child: _InstrumentPickerTile(
                      label: 'В',
                      instrument: ctrl.toInstrument,
                      fallbackCode: ctrl.toCode,
                      onTap: () => _pickInstrument(
                        context,
                        title: 'Целевой актив',
                        catalog: ctrl.catalog,
                        onSelected: ctrl.selectTo,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('converter_submit_button'),
                onPressed: ctrl.canConvert ? ctrl.convert : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Конвертировать',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (result != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.accent.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${MarketNumberFormatter.formatConvertedAmount(result.amount)} ${result.fromInstrument.code} =',
                  style: TerminalTheme.tabular(
                    context,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${MarketNumberFormatter.formatConvertedAmount(result.convertedAmount)} ${result.toInstrument.code}',
                  style: TerminalTheme.tabular(
                    context,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: palette.bull,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: palette.border, height: 1),
                const SizedBox(height: 10),
                _rateRow(
                  context,
                  'Прямой курс',
                  '1 ${result.fromInstrument.code} = ${MarketNumberFormatter.formatConvertedAmount(result.directRate)} ${result.toInstrument.code}',
                ),
                const SizedBox(height: 4),
                _rateRow(
                  context,
                  'Обратный курс',
                  '1 ${result.toInstrument.code} = ${MarketNumberFormatter.formatConvertedAmount(result.inverseRate)} ${result.fromInstrument.code}',
                ),
                const SizedBox(height: 4),
                _rateRow(
                  context,
                  'Актуальность',
                  MarketNumberFormatter.formatTimestamp(result.rateTimestamp),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _rateRow(BuildContext context, String label, String value) {
    final palette = TerminalTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: palette.textSecondary, fontSize: 12),
        ),
        Text(
          value,
          style: TerminalTheme.tabular(
            context,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Future<void> _pickInstrument(
    BuildContext context, {
    required String title,
    required List<ConvertibleInstrument> catalog,
    required ValueChanged<String> onSelected,
  }) async {
    if (catalog.isEmpty) return;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _InstrumentSearchSheet(title: title, catalog: catalog),
    );
    if (chosen != null) {
      onSelected(chosen);
    }
  }
}

class _InstrumentPickerTile extends StatelessWidget {
  const _InstrumentPickerTile({
    required this.label,
    required this.instrument,
    required this.fallbackCode,
    required this.onTap,
  });

  final String label;
  final ConvertibleInstrument? instrument;
  final String fallbackCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TerminalTheme.of(context);
    final code = instrument?.code ?? fallbackCode;
    final category = instrument?.category ?? AssetCategory.forex;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            AssetBadge(symbol: code, category: category, size: 32),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 10.5,
                    ),
                  ),
                  Text(
                    code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: palette.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _InstrumentSearchSheet extends StatefulWidget {
  const _InstrumentSearchSheet({
    required this.title,
    required this.catalog,
  });

  final String title;
  final List<ConvertibleInstrument> catalog;

  @override
  State<_InstrumentSearchSheet> createState() => _InstrumentSearchSheetState();
}

class _InstrumentSearchSheetState extends State<_InstrumentSearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final palette = TerminalTheme.of(context);
    final items = widget.catalog.where((item) {
      if (_query.trim().isEmpty) return true;
      final q = _query.trim().toLowerCase();
      return item.code.toLowerCase().contains(q) ||
          item.name.toLowerCase().contains(q);
    }).toList(growable: false);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                widget.title,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Поиск (USD, BTC, AAPL, MDL)...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    leading: AssetBadge(
                      symbol: item.code,
                      category: item.category,
                      size: 34,
                    ),
                    title: Text(
                      item.code,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text('${item.name} • ${item.category.labelRu}'),
                    trailing: Text(
                      '\$${MarketNumberFormatter.formatPrice(item.usdPricePerUnit)}',
                      style: TerminalTheme.tabular(context, fontSize: 13),
                    ),
                    onTap: () => Navigator.of(context).pop(item.code),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
