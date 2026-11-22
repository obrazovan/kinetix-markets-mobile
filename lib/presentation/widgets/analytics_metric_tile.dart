import 'package:material_ui/material_ui.dart';

import '../../app/theme/terminal_theme.dart';

/// Compact KPI card used on 7D and 30D comparison analytics screens.
class AnalyticsMetricTile extends StatelessWidget {
  const AnalyticsMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.valueColor,
    this.icon,
  });

  final String label;
  final String value;
  final String? subtitle;
  final Color? valueColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = TerminalTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: palette.textSecondary),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TerminalTheme.tabular(
              context,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: valueColor ?? palette.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                color: palette.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
