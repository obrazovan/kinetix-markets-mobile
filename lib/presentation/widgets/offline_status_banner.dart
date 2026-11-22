import 'package:material_ui/material_ui.dart';

import '../../app/theme/terminal_theme.dart';
import '../../core/formatters/number_formatter.dart';

/// Explicit offline / cached data freshness and partial warning banner.
class OfflineStatusBanner extends StatelessWidget {
  const OfflineStatusBanner({
    super.key,
    required this.isOffline,
    required this.fetchedAt,
    required this.warnings,
    required this.onRetry,
  });

  final bool isOffline;
  final DateTime? fetchedAt;
  final List<String> warnings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (!isOffline && warnings.isEmpty) {
      return const SizedBox.shrink();
    }

    final palette = TerminalTheme.of(context);
    final timestampLabel = fetchedAt == null
        ? 'неизвестно'
        : MarketNumberFormatter.formatTimestamp(fetchedAt!);

    final title = isOffline
        ? 'Офлайн-режим • Данные из кэша от $timestampLabel'
        : warnings.first;

    final accentColor = isOffline ? palette.warning : palette.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(
            isOffline ? Icons.cloud_off_rounded : Icons.info_outline_rounded,
            color: accentColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isOffline)
                  Text(
                    'Конвертация и графики доступны без интернета',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Обновить',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
